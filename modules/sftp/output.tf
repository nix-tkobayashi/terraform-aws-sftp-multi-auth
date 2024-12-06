# Output Transfer Server Addresses
output "transfer_server_addresses" {
  value = aws_transfer_server.sftp_server.endpoint
}
