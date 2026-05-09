# skill: devops/security
# triggers: secrets, vault, sops, iam, security, scan, trivy, cve, hardening

## Secrets
```bash
# Create + read from AWS Secrets Manager
aws secretsmanager create-secret --name /prod/app/key \
  --secret-string "$(openssl rand -base64 32)"
aws secretsmanager get-secret-value --secret-id /prod/app/key \
  --query SecretString --output text

# SOPS encrypt
sops --encrypt --age <age-public-key> secrets.yaml > secrets.enc.yaml
```

## External Secrets (K8s — preferred)
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata: { name: app-secrets }
spec:
  refreshInterval: 1h
  secretStoreRef: { name: aws-secrets-manager, kind: ClusterSecretStore }
  target: { name: app-secrets, creationPolicy: Owner }
  data:
    - secretKey: db-password
      remoteRef: { key: /prod/app/db-password }
```

## Trivy Scanning
```bash
trivy image --severity HIGH,CRITICAL --exit-code 1 $IMAGE:$TAG
trivy fs --security-checks vuln,secret,config .
trivy k8s --report summary cluster
```

## Hardening Checklist
```
K8s:
  ✓ runAsNonRoot: true in all pods
  ✓ No privileged containers
  ✓ NetworkPolicy default-deny
  ✓ Resource limits on all containers
  ✓ Read-only root filesystem where possible
  ✓ Drop all capabilities: capabilities.drop: [ALL]

AWS:
  ✓ MFA on all IAM users
  ✓ No root access keys
  ✓ CloudTrail enabled all regions
  ✓ GuardDuty enabled
  ✓ Config Rules for drift detection
  ✓ S3 Block Public Access on all buckets

CI:
  ✓ OIDC auth — no static credentials
  ✓ Pin actions to full SHA (not tag)
  ✓ Required reviewers for prod deploys
  ✓ Secrets scanning in pipeline
```

## SBOM + Supply Chain
```bash
# Generate SBOM
syft $IMAGE:$TAG -o spdx-json > sbom.json

# Sign image
cosign sign --key cosign.key $IMAGE:$TAG

# Verify
cosign verify --key cosign.pub $IMAGE:$TAG
```

## Secret Detection in Git
```bash
# Pre-commit hook
pip install detect-secrets
detect-secrets scan > .secrets.baseline
detect-secrets audit .secrets.baseline

# Block commit if secrets found
git config core.hooksPath .githooks
```

## FORBIDDEN
```
FORBIDDEN: Static AWS access keys in GitHub Actions secrets.
FORBIDDEN: Secrets in environment variables committed to Docker images.
FORBIDDEN: Shared IAM users — one role per workload.
FORBIDDEN: Root account API keys — ever.
FORBIDDEN: Skipping Trivy scan in CI for "quick deploys."
```

## Gotchas

1. **`docker inspect` reveals env vars.** Any secret passed as `ENV` in a Dockerfile is visible to anyone with docker inspect on that image. Use `--secret` mount or External Secrets Operator instead.

2. **IRSA ≠ node role.** If your pod can assume any role the EC2 node can, IRSA isn't set up correctly. Verify with `aws sts get-caller-identity` from inside the pod.

3. **Rotating secrets doesn't invalidate cached tokens.** After rotating an AWS secret, apps holding the old value keep working until their token TTL expires. Force rotation by restarting pods: `kubectl rollout restart deployment/app`.

4. **GuardDuty findings have a 15-min lag.** Don't assume real-time detection. Pair with CloudTrail for immediate audit trail.

5. **SOPS encrypted files still reveal structure.** SOPS encrypts values but not keys. `aws_access_key_id: ENC[...]` tells attackers what secrets you have even if they can't decrypt.

## Related Skills
- **devops/cloud**: IAM least privilege patterns, IRSA setup for K8s pods
- **devops/cicd**: OIDC auth for GitHub Actions — no static keys
- **devops/containers**: Pod security contexts, non-root users, read-only filesystems
