# skill: devops/cloud
# triggers: aws, s3, ec2, rds, iam, vpc, lambda, ecr, eks, azure, gcp, cloud

## AWS CLI Quick Reference
```bash
# EKS
aws eks update-kubeconfig --name <cluster> --region us-east-1

# ECR login
aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_URI

# Secrets
aws secretsmanager get-secret-value --secret-id /prod/app/key --query SecretString --output text

# SSM
aws ssm get-parameter --name /prod/app/key --with-decryption --query Parameter.Value

# S3 sync
aws s3 sync ./dist s3://bucket/path --delete --cache-control max-age=86400
```

## VPC Layout (3-tier)
```
10.0.0.0/16
├── Public  10.0.1-3.0/24   — ALB, NAT GW (3 AZs)
├── Private 10.0.11-13.0/24 — EKS nodes (3 AZs)
└── Data    10.0.21-23.0/24 — RDS, ElastiCache (3 AZs)
```

## Cost Levers
- Spot for non-prod (saves ~70%)
- S3 Intelligent-Tiering on buckets >10GB
- RDS gp3 > gp2; reserved for prod
- Karpenter > Cluster Autoscaler
- CloudWatch: always set retention (never unlimited)

## EKS Checklist
- [ ] Private API endpoint
- [ ] IRSA enabled — no node instance profile for app perms
- [ ] Node groups in private subnets
- [ ] Cluster logging: api, audit, authenticator enabled

## Lambda Pattern
```python
import json, boto3, os
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

logger = Logger()
tracer = Tracer()

@logger.inject_lambda_context
@tracer.capture_lambda_handler
def handler(event: dict, context: LambdaContext) -> dict:
    logger.info("Processing", extra={"event": event})
    try:
        result = process(event)
        return {"statusCode": 200, "body": json.dumps(result)}
    except Exception as e:
        logger.exception("Failed")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
```

## IAM Least Privilege Pattern
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["s3:GetObject", "s3:PutObject"],
    "Resource": "arn:aws:s3:::my-bucket/${aws:PrincipalTag/env}/*"
  }]
}
```

## IRSA (Pod → AWS permissions without node role)
```bash
# Create OIDC provider for cluster
eksctl utils associate-iam-oidc-provider --cluster my-cluster --approve

# Create SA with role
eksctl create iamserviceaccount \
  --name my-app \
  --namespace prod \
  --cluster my-cluster \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
  --approve
```
```yaml
# K8s SA annotation
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/my-role
```

## EventBridge (event-driven architecture)
```python
import boto3
eb = boto3.client('events')

# Publish event
eb.put_events(Entries=[{
    'Source': 'myapp.orders',
    'DetailType': 'OrderCreated',
    'Detail': json.dumps({ 'orderId': '123', 'userId': 'usr_abc' }),
    'EventBusName': 'myapp-events',
}])
```
```json
// Rule — route to Lambda
{
  "source": ["myapp.orders"],
  "detail-type": ["OrderCreated"]
}
```

## SQS Pattern (reliable async)
```bash
# Create queue
aws sqs create-queue --queue-name myapp-jobs.fifo \
  --attributes FifoQueue=true,ContentBasedDeduplication=true

# Send
aws sqs send-message --queue-url $URL \
  --message-body '{"job":"process","id":"123"}' \
  --message-group-id orders

# Receive + delete (always delete after processing)
aws sqs receive-message --queue-url $URL --max-number-of-messages 10 \
  | jq -r '.Messages[] | .ReceiptHandle' \
  | xargs -I{} aws sqs delete-message --queue-url $URL --receipt-handle {}
```

## CloudWatch Alarms
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "HighErrorRate" \
  --metric-name "5XXError" \
  --namespace "AWS/ApplicationELB" \
  --statistic Sum \
  --period 60 --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-east-1:ACCOUNT:alerts
```
