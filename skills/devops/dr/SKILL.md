# skill: devops/dr
# triggers: backup, disaster recovery, rto, rpo, restore, failover, snapshot, point-in-time

## DR Objectives
```
RTO (Recovery Time Objective) — how long can you be down?
  → Tier 1 (revenue-critical): <1h
  → Tier 2 (internal tools):   <4h
  → Tier 3 (dev/staging):      <24h

RPO (Recovery Point Objective) — how much data loss is acceptable?
  → Tier 1: <15 min (continuous replication)
  → Tier 2: <1h    (hourly snapshots)
  → Tier 3: <24h   (daily backups)
```

## Postgres Backups
```bash
# Continuous WAL archiving to S3 (pg_basebackup + WAL-G)
# Install WAL-G
export WALG_S3_PREFIX=s3://my-backups/postgres
export AWS_REGION=us-east-1

# Full backup (run daily)
wal-g backup-push $PGDATA

# List backups
wal-g backup-list DETAIL

# Restore to point-in-time
wal-g backup-fetch $PGDATA LATEST
# then: restore_command = 'wal-g wal-fetch %f %p' in recovery.conf
# and:  recovery_target_time = '2024-01-15 14:30:00'

# RDS — automated via AWS (enable)
aws rds modify-db-instance \
  --db-instance-identifier mydb \
  --backup-retention-period 7 \
  --preferred-backup-window "02:00-03:00"

# Manual snapshot
aws rds create-db-snapshot --db-instance-identifier mydb --db-snapshot-identifier mydb-$(date +%Y%m%d)
```

## S3 Backup Strategy
```hcl
# Versioning + replication
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_replication_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  role   = aws_iam_role.replication.arn
  rule {
    id     = "replicate-all"
    status = "Enabled"
    destination {
      bucket        = aws_s3_bucket.replica.arn  # in different region
      storage_class = "STANDARD_IA"
    }
  }
}

# Lifecycle: move old versions to cheaper storage
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    id     = "archive-old-versions"
    status = "Enabled"
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }
    noncurrent_version_expiration { noncurrent_days = 365 }
  }
}
```

## Backup Verification (monthly)
```bash
#!/usr/bin/env bash
set -euo pipefail

# Restore to test instance and verify
SNAPSHOT=$(aws rds describe-db-snapshots \
  --query 'reverse(sort_by(DBSnapshots, &SnapshotCreateTime))[0].DBSnapshotIdentifier' \
  --output text)

aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier restore-test-$$ \
  --db-snapshot-identifier $SNAPSHOT \
  --db-instance-class db.t3.small

# Wait for it to be available
aws rds wait db-instance-available --db-instance-identifier restore-test-$$

# Run validation query
psql $RESTORE_URL -c "SELECT COUNT(*) FROM users; SELECT MAX(created_at) FROM orders;"

# Clean up
aws rds delete-db-instance --db-instance-identifier restore-test-$$ --skip-final-snapshot
echo "DR test passed: restored from $SNAPSHOT"
```

## Runbook — Postgres Failover
```bash
# 1. Detect failure (Prometheus alert: pg_up == 0)
# 2. Promote RDS read replica
aws rds promote-read-replica --db-instance-identifier mydb-replica

# 3. Update connection string (Route53 CNAME to new primary)
aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID \
  --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{
    "Name":"db.example.com","Type":"CNAME","TTL":60,
    "ResourceRecords":[{"Value":"mydb-replica.xxx.us-east-1.rds.amazonaws.com"}]}}]}'

# 4. Verify app connectivity
curl -f https://api.example.com/health
```

## DR Checklist
```
Monthly:
  □ Restore backup to test environment
  □ Verify data integrity (row counts, latest timestamps)
  □ Update runbook if anything changed
  □ Test alert firing (trigger a synthetic failure)

Quarterly:
  □ Full DR drill — simulate regional outage
  □ Time the recovery, compare vs RTO target
  □ Review and update RPO targets vs backup frequency
```
