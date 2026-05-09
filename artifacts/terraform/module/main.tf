locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# ── Replace the resources below with your actual module content ──

# Example: ECS service, RDS instance, Lambda, S3 bucket, etc.
# resource "aws_..." "main" {
#   name = local.name_prefix
#   tags = local.common_tags
# }
