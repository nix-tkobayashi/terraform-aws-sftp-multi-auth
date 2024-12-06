# Elastic IP for SFTP Server
resource "aws_eip" "sftp1" {
  address                   = null
  associate_with_private_ip = null
  customer_owned_ipv4_pool  = null
  domain                    = "vpc"
  instance                  = null
  network_border_group      = data.aws_region.current.name
  public_ipv4_pool          = "amazon"
}

# Elastic IP for SFTP Server
resource "aws_eip" "sftp2" {
  address                   = null
  associate_with_private_ip = null
  customer_owned_ipv4_pool  = null
  domain                    = "vpc"
  instance                  = null
  network_border_group      = data.aws_region.current.name
  public_ipv4_pool          = "amazon"
}
