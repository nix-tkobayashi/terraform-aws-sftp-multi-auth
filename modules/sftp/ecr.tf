# ECR Repository for Lambda Function
resource "aws_ecr_repository" "sftp_lambda" {
  name                 = "sftp-lambda"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
