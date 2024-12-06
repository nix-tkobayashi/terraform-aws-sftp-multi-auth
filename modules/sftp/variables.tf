# S3 bucket name
variable "s3_bucket_name" {
  type = string
}

# Definition of SFTP users and SSH keys or passwords
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

# Lambda function settings
variable "lambda" {
  type = object({
    timeout        = number
    memory_size    = number
    retry_attempts = number
  })
  default = {
    timeout        = 30
    memory_size    = 128
    retry_attempts = 2
  }
}

# SQS settings
variable "sqs" {
  type = object({
    max_receive_count          = number
    visibility_timeout_seconds = number
    dlq_message_retention_days = number
  })
  default = {
    max_receive_count          = 3
    visibility_timeout_seconds = 300
    dlq_message_retention_days = 14
  }
}
