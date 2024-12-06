# Lambda function
resource "aws_lambda_function" "process_upload" {
  function_name = "process-sftp-upload"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.sftp_lambda.repository_url}:latest"

  image_config {
    command = ["index.handler"]
  }

  timeout     = var.lambda.timeout
  memory_size = var.lambda.memory_size
}

# Lambda function asynchronous invocation configuration
resource "aws_lambda_function_event_invoke_config" "process_upload_async_config" {
  function_name = aws_lambda_function.process_upload.function_name

  maximum_retry_attempts = var.lambda.retry_attempts
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-sftp-process-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Lambda function policy
resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.sftp_bucket.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Add access to ECR
resource "aws_iam_role_policy_attachment" "lambda_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.lambda_role.name
}

### Lambda function for SFTP authentication

# Package the Lambda function code into a ZIP file
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/src/lambda_function.zip"
}

# Lambda function
resource "aws_lambda_function" "sftp_auth" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "sftp_auth_function"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SecretsManagerRegion = data.aws_region.current.name
    }
  }
}

# IAM role for Lambda execution
resource "aws_iam_role" "lambda_exec" {
  name = "sftp_auth_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# CloudWatch Logs group for Lambda
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/sftp_auth_function"
  retention_in_days = 14
}

# Attach the basic execution policy for Lambda
resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_exec.name
}

# Custom policy for Secrets Manager access
resource "aws_iam_role_policy" "lambda_secrets_manager_access" {
  name = "lambda_secrets_manager_access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:aws/transfer/*"
      }
    ]
  })
}

# Permissions for Transfer Server to call the Lambda function
resource "aws_lambda_permission" "allow_transfer_to_call_lambda" {
  statement_id  = "AllowTransferInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sftp_auth.function_name
  principal     = "transfer.amazonaws.com"
  source_arn    = aws_transfer_server.sftp_server.arn
}
