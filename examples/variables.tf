# Definition of SFTP users and SSH keys
variable "sftp_users" {
  type = list(object({
    user_name  = string
    ssh_key    = optional(string)
    password   = optional(string)
    ip_address = string
  }))

  validation {
    condition = alltrue([
      for user in var.sftp_users :
      (user.ssh_key != null) != (user.password != null)
    ])
    error_message = "Each user must have either an SSH key or a password set, but not both."
  }
}

# S3 bucket configuration
variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket for SFTP server storage"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.s3_bucket_name))
    error_message = "S3 bucket name must contain only lowercase letters, numbers, and hyphens, and must begin and end with a letter or number"
  }
}

# Lambda function configuration
variable "lambda_settings" {
  type = object({
    timeout        = number
    retry_attempts = number
    memory_size    = number
  })
  description = "Lambda function settings"
  default = {
    timeout        = 180
    retry_attempts = 0
    memory_size    = 128
  }

  validation {
    condition     = var.lambda_settings.timeout >= 1 && var.lambda_settings.timeout <= 900
    error_message = "Lambda timeout must be between 1 and 900 seconds"
  }

  validation {
    condition     = var.lambda_settings.memory_size >= 128 && var.lambda_settings.memory_size <= 10240
    error_message = "Lambda memory size must be between 128MB and 10240MB"
  }
}

# SQS configuration
variable "sqs_settings" {
  type = object({
    max_receive_count          = number
    visibility_timeout_seconds = number
    dlq_message_retention_days = number
  })
  description = "SQS queue settings"
  default = {
    max_receive_count          = 5
    visibility_timeout_seconds = 240
    dlq_message_retention_days = 14
  }

  validation {
    condition     = var.sqs_settings.visibility_timeout_seconds >= 0 && var.sqs_settings.visibility_timeout_seconds <= 43200
    error_message = "SQS visibility timeout must be between 0 and 43200 seconds"
  }

  validation {
    condition     = var.sqs_settings.dlq_message_retention_days >= 1 && var.sqs_settings.dlq_message_retention_days <= 14
    error_message = "DLQ message retention period must be between 1 and 14 days"
  }
}
