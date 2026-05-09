# skill: devops/cost
# triggers: cost, finops, aws cost, billing, optimize, spend, savings, reserved, spot

## Cost Levers by Service
```bash
# EC2 / EKS Nodes
# Spot instances: up to 90% savings for fault-tolerant workloads
# Savings Plans: commit 1-3yr, save 20-40%
# Right-sizing: check CloudWatch CPU/mem < 40% avg → downsize

# RDS
# gp3 > gp2 (same perf, lower cost)
# Reserved instances for prod (1yr = ~40% off)
# Multi-AZ only for prod — not dev/staging
# Aurora Serverless v2 for variable workloads

# S3
# Intelligent-Tiering for buckets > 10GB, unknown access patterns
# Lifecycle rules: Standard → IA (30d) → Glacier (90d) → delete (365d)
# Block public access + delete unused buckets

# CloudWatch
# Set retention: 7d for dev, 30d for staging, 90d for prod
# Never leave at "Never expire" (most expensive)

# Lambda
# ARM64 (Graviton2): same perf, 20% cheaper
# Provisioned concurrency only for latency-critical (not general use)
```

## Cost Alerts (Terraform)
```hcl
resource "aws_budgets_budget" "monthly" {
  name         = "monthly-spend"
  budget_type  = "COST"
  limit_amount = "500"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["infra@example.com"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["infra@example.com"]
  }
}
```

## Cost Analysis Commands
```bash
# Top 10 services by cost this month
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query 'ResultsByTime[0].Groups | sort_by(@, &Metrics.BlendedCost.Amount) | reverse(@) | [0:10]' \
  --output table

# EC2 unused / over-provisioned (Compute Optimizer)
aws compute-optimizer get-ec2-instance-recommendations \
  --filters Name=Finding,Values=Overprovisioned

# Unattached EBS volumes
aws ec2 describe-volumes --filters Name=status,Values=available \
  --query 'Volumes[*].[VolumeId,Size,CreateTime]' --output table

# Old snapshots (>90 days)
aws ec2 describe-snapshots --owner-ids self \
  --query 'Snapshots[?StartTime<`'$(date -d "-90 days" +%Y-%m-%d)'`].[SnapshotId,StartTime,VolumeSize]' \
  --output table
```

## Karpenter (spot node auto-provisioning)
```yaml
# NodePool with spot preference
apiVersion: karpenter.sh/v1
kind: NodePool
metadata: { name: default }
spec:
  template:
    spec:
      requirements:
        - { key: karpenter.sh/capacity-type, operator: In, values: [spot, on-demand] }
        - { key: node.kubernetes.io/instance-type, operator: In,
            values: [m5.large, m5.xlarge, m5a.large, m6i.large] }
      nodeClassRef: { apiVersion: karpenter.k8s.aws/v1, kind: EC2NodeClass, name: default }
  limits: { cpu: 1000 }
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 30s
```

## Monthly FinOps Review
```
□ Check budget alert emails — investigate any >80% threshold
□ Review Cost Explorer: top 3 services, compare vs last month
□ Unused resources: EBS volumes, elastic IPs, old snapshots, idle RDS
□ EC2 right-sizing: Compute Optimizer recommendations
□ Reserved coverage: < 70% coverage → buy more savings plans
□ Data transfer: largest cost surprise is usually egress — check CloudFront usage
```
