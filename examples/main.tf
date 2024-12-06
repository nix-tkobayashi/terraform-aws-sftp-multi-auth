# Terraform configuration
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Tokyo region
provider "aws" {
  region = "ap-northeast-1"
}

# Virginia region
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

# Get current region and account id
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# SFTP module
module "sftp" {
  source = "../modules/sftp"

  s3_bucket_name = var.s3_bucket_name
  sftp_users     = var.sftp_users
  lambda         = var.lambda_settings
  sqs            = var.sqs_settings
}
