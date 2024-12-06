# S3 bucket for SFTP file storage
resource "aws_s3_bucket" "sftp_bucket" {
  bucket = var.s3_bucket_name
}

# AWS Transfer Family SFTP server
resource "aws_transfer_server" "sftp_server" {
  identity_provider_type = "AWS_LAMBDA"
  protocols              = ["SFTP"]
  endpoint_type          = "VPC"

  endpoint_details {
    vpc_id = aws_vpc.main.id
    subnet_ids = [
      aws_subnet.public[0].id,
      aws_subnet.public[1].id
    ]
    security_group_ids = [aws_security_group.sftp.id]
    address_allocation_ids = [
      aws_eip.sftp1.id,
      aws_eip.sftp2.id
    ]
  }

  function = aws_lambda_function.sftp_auth.arn

  logging_role = aws_iam_role.transfer_logging_role.arn

  tags = {
    Name = "sftp-server"
  }

  # Unassociate Elastic IP
  lifecycle {
    create_before_destroy = true
  }

  # Associate new Elastic IP
  depends_on = [aws_lambda_function.sftp_auth]
}

# IAM role for SFTP user
resource "aws_iam_role" "sftp_user_role" {
  name = "sftp-user-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "transfer.amazonaws.com"
      }
    }]
  })
}

# IAM policy for SFTP user to access S3
resource "aws_iam_role_policy" "sftp_user_policy" {
  role = aws_iam_role.sftp_user_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ]
      Resource = [
        aws_s3_bucket.sftp_bucket.arn
      ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          "${aws_s3_bucket.sftp_bucket.arn}/*"
        ]
    }]
  })
}

# IAM role for SFTP logging
resource "aws_iam_role" "transfer_logging_role" {
  name = "transfer-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "transfer.amazonaws.com"
      }
    }]
  })
}

# Attach logging policy to IAM role
resource "aws_iam_role_policy_attachment" "transfer_logging_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
  role       = aws_iam_role.transfer_logging_role.name
}
