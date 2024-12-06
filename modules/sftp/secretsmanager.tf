# Secrets Manager
resource "random_id" "secret_suffix" {
  for_each    = { for user in var.sftp_users : user.user_name => user }
  byte_length = 8
}

# Secrets Manager
resource "aws_secretsmanager_secret" "sftp_users" {
  for_each = { for user in var.sftp_users : user.user_name => user }
  name     = "aws/transfer/${aws_transfer_server.sftp_server.id}/${each.key}"
}

# Secrets Manager Secret Version
resource "aws_secretsmanager_secret_version" "sftp_users" {
  for_each  = { for user in var.sftp_users : user.user_name => user }
  secret_id = aws_secretsmanager_secret.sftp_users[each.key].id
  secret_string = jsonencode({
    Password      = each.value.password != null ? each.value.password : null
    PublicKey     = each.value.ssh_key != null ? each.value.ssh_key : null
    Role          = aws_iam_role.sftp_user_role.arn
    HomeDirectory = "/${aws_s3_bucket.sftp_bucket.id}/${each.key}"
  })
}
