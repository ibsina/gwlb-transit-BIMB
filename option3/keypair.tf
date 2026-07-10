############################################################
# KEY PAIR
############################################################

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.project_name}-keypair"
  public_key = tls_private_key.ssh_key.public_key_openssh
  tags       = var.common_tags
}

resource "aws_secretsmanager_secret" "ec2_ssh_private_key" {
  name        = "bimb-${var.project_name}-keypair"
  description = "Private SSH key for EC2 instance"
  tags = merge(
    var.common_tags,
    {
      Project_Name = var.project_name,
      Environment  = var.environment,
      Department   = "DevOps"
    }
  )
}

resource "aws_secretsmanager_secret_version" "ssh_private_key_version" {
  secret_id     = aws_secretsmanager_secret.ec2_ssh_private_key.id
  secret_string = tls_private_key.ssh_key.private_key_pem
}
