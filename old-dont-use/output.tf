
output "Username" {
  value = "admin"
}

output "FGT1-Password" {
  value = aws_instance.fgtvm.id
}

output "FGT2-Password" {
  value = aws_instance.fgtvm2.id
}

output "FGT3-Password" {
  value = aws_instance.fgtvm3.id
}

output "LoadBalancerPrivateIP" {
  value = data.aws_network_interface.vpcendpointip.private_ip
}

output "LoadBalancerPrivateIP2" {
  value = data.aws_network_interface.vpcendpointipaz2.private_ip
}

output "LoadBalancerPrivateIP3" {
  value = data.aws_network_interface.vpcendpointipaz3.private_ip
}

output "FGTVPC" {
  value = aws_vpc.fgtvm-vpc.id
}

output "SSH_KeyPair_Name" {
  description = "Name of the AWS EC2 Key Pair"
  value       = aws_key_pair.ec2_key_pair.key_name
}

output "SSH_PrivateKey_SecretARN" {
  description = "AWS Secrets Manager ARN storing the private key (use this to retrieve the key)"
  value       = aws_secretsmanager_secret.ec2_ssh_private_key.arn
}
