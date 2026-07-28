// AWS VPC - FortiGate Security VPC (NS & EW clusters)
resource "aws_vpc" "fgtvm-vpc" {
  cidr_block           = var.vpccidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = "bimb-inspection-vpc-ns-ew"
  }
}

// ========================================
// North-South Cluster Subnets
// ========================================

resource "aws_subnet" "ns_mgmtsubnetaz1" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.ns_mgmtcidraz1
  availability_zone = var.az1
  tags = {
    Name = "bimb-ns-mgmt-az1"
  }
}

resource "aws_subnet" "ns_mgmtsubnetaz2" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.ns_mgmtcidraz2
  availability_zone = var.az2
  tags = {
    Name = "bimb-ns-mgmt-az2"
  }
}

resource "aws_subnet" "ns_privatesubnetaz1" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.ns_privatecidraz1
  availability_zone = var.az1
  tags = {
    Name = "bimb-ns-private-az1"
  }
}

resource "aws_subnet" "ns_privatesubnetaz2" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.ns_privatecidraz2
  availability_zone = var.az2
  tags = {
    Name = "bimb-ns-private-az2"
  }
}

// ========================================
// East-West Cluster Subnets
// ========================================

resource "aws_subnet" "ew_mgmtsubnetaz1" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.ew_mgmtcidraz1
  availability_zone = var.az1
  tags = {
    Name = "bimb-ew-mgmt-az1"
  }
}

resource "aws_subnet" "ew_mgmtsubnetaz2" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.ew_mgmtcidraz2
  availability_zone = var.az2
  tags = {
    Name = "bimb-ew-mgmt-az2"
  }
}

resource "aws_subnet" "ew_privatesubnetaz1" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.ew_privatecidraz1
  availability_zone = var.az1
  tags = {
    Name = "bimb-ew-private-az1"
  }
}

resource "aws_subnet" "ew_privatesubnetaz2" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.ew_privatecidraz2
  availability_zone = var.az2
  tags = {
    Name = "bimb-ew-private-az2"
  }
}

resource "aws_subnet" "ew_transitsubnetaz1" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.ew_attachcidraz1
  availability_zone = var.az1
  tags = {
    Name = "bimb-ew-transit-az1"
  }
}

resource "aws_subnet" "ew_transitsubnetaz2" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.ew_attachcidraz2
  availability_zone = var.az2
  tags = {
    Name = "bimb-ew-transit-az2"
  }
}

resource "aws_subnet" "ew_gwlbsubnetaz1" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.ew_gwlbcidraz1
  availability_zone = var.az1
  tags = {
    Name = "bimb-ew-gwlb-az1"
  }
}

resource "aws_subnet" "ew_gwlbsubnetaz2" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.ew_gwlbcidraz2
  availability_zone = var.az2
  tags = {
    Name = "bimb-ew-gwlb-az2"
  }
}
