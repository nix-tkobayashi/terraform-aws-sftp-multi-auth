# Create SQS queue
resource "aws_sqs_queue" "sftp_upload_queue" {
  name                       = "sftp-upload-queue"
  visibility_timeout_seconds = var.sqs.visibility_timeout_seconds
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.sftp_upload_dlq.arn
    maxReceiveCount     = var.sqs.max_receive_count
  })
}

# Create dead letter queue
resource "aws_sqs_queue" "sftp_upload_dlq" {
  name                      = "sftp-upload-dlq"
  message_retention_seconds = var.sqs.dlq_message_retention_days * 24 * 60 * 60
}

# Add policy to SQS queue
resource "aws_sqs_queue_policy" "sftp_upload_queue_policy" {
  queue_url = aws_sqs_queue.sftp_upload_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3ToSendMessage"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.sftp_upload_queue.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_s3_bucket.sftp_bucket.arn
          }
        }
      }
    ]
  })
}
# Add event notification to S3 bucket
resource "aws_s3_bucket_notification" "bucket_notification2" {
  bucket = aws_s3_bucket.sftp_bucket.id

  queue {
    queue_arn = aws_sqs_queue.sftp_upload_queue.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sqs_queue_policy.sftp_upload_queue_policy]
}

# Add SQS permissions to Lambda function IAM role
resource "aws_iam_role_policy_attachment" "lambda_sqs" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# Change Lambda function trigger to SQS
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.sftp_upload_queue.arn
  function_name    = aws_lambda_function.process_upload.arn
  batch_size       = 1
}
