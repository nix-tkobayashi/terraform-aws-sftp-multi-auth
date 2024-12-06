# Get current region and account id
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Data source for available AZs
data "aws_availability_zones" "available" {
  state = "available"
}
