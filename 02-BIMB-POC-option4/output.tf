// ========================================
// Outputs
// ========================================

output "Username" {
  value = "admin"
}

// North-South Cluster Outputs
output "FGT-NS1-Password" {
  description = "FortiGate NS1 Password (Instance ID)"
  value       = aws_instance.fgtvm_ns1.id
}

output "FGT-NS2-Password" {
  description = "FortiGate NS2 Password (Instance ID)"
  value       = aws_instance.fgtvm_ns2.id
}

output "FGT-NS1-Management-IP" {
  description = "FortiGate NS1 Management Private IP"
  value       = aws_network_interface.ns1_eth0.private_ip
}

output "FGT-NS2-Management-IP" {
  description = "FortiGate NS2 Management Private IP"
  value       = aws_network_interface.ns2_eth0.private_ip
}

output "NS-GWLB-ARN" {
  description = "North-South GWLB ARN"
  value       = aws_lb.ns_gateway_lb.arn
}

output "NS-GWLB-Service-Name" {
  description = "North-South GWLB Endpoint Service Name"
  value       = aws_vpc_endpoint_service.ns_gwlbservice.service_name
}

// East-West Cluster Outputs
output "FGT-EW1-Password" {
  description = "FortiGate EW1 Password (Instance ID)"
  value       = aws_instance.fgtvm_ew1.id
}

output "FGT-EW2-Password" {
  description = "FortiGate EW2 Password (Instance ID)"
  value       = aws_instance.fgtvm_ew2.id
}

output "FGT-EW1-Management-IP" {
  description = "FortiGate EW1 Management Private IP"
  value       = aws_network_interface.ew1_eth0.private_ip
}

output "FGT-EW2-Management-IP" {
  description = "FortiGate EW2 Management Private IP"
  value       = aws_network_interface.ew2_eth0.private_ip
}

output "EW-GWLB-ARN" {
  description = "East-West GWLB ARN"
  value       = aws_lb.ew_gateway_lb.arn
}

output "EW-GWLB-Service-Name" {
  description = "East-West GWLB Endpoint Service Name"
  value       = aws_vpc_endpoint_service.ew_gwlbservice.service_name
}

output "EW-GWLB-Endpoint-ID" {
  description = "East-West GWLB Endpoint ID"
  value       = aws_vpc_endpoint.ew_gwlbendpoint.id
}

output "EW-LoadBalancer-PrivateIP-AZ1" {
  description = "East-West GWLB Endpoint Private IP in AZ1"
  value       = data.aws_network_interface.ew_vpcendpointip_az1.private_ip
}

output "EW-LoadBalancer-PrivateIP-AZ2" {
  description = "East-West GWLB Endpoint Private IP in AZ2"
  value       = data.aws_network_interface.ew_vpcendpointip_az2.private_ip
}

// VPC and Common Outputs
output "VPC-ID" {
  description = "Security VPC ID"
  value       = aws_vpc.fgtvm-vpc.id
}

output "SSH-KeyPair-Name" {
  description = "Name of the AWS EC2 Key Pair"
  value       = aws_key_pair.ec2_key_pair.key_name
}

output "SSH-PrivateKey-SecretARN" {
  description = "AWS Secrets Manager ARN storing the private key"
  value       = aws_secretsmanager_secret.ec2_ssh_private_key.arn
}

output "EBS-KMS-Key-ARN" {
  description = "ARN of the KMS key used to encrypt FortiGate EBS volumes"
  value       = aws_kms_key.ebs_key.arn
}

output "EBS-KMS-Key-Alias" {
  description = "Alias of the KMS key used to encrypt FortiGate EBS volumes"
  value       = aws_kms_alias.ebs_key_alias.name
}
