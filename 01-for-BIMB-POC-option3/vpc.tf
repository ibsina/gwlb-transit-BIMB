// AWS VPC - FortiGate
resource "aws_vpc" "fgtvm-vpc" {
  cidr_block           = var.vpccidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = "terraform fgt demo"
  }
}

resource "aws_subnet" "mgmtsubnetaz1" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.mgmtcidraz1
  availability_zone = var.az1
  tags = {
    Name = "bimb-inspection-mgmt-az1"
  }
}
//
resource "aws_subnet" "mgmtsubnetaz2" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.mgmtcidraz2
  availability_zone = var.az2
  tags = {
    Name = "bimb-inspection-mgmt-az2"
  }
}

resource "aws_subnet" "mgmtsubnetaz3" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.mgmtcidraz3
  availability_zone = var.az3
  tags = {
    Name = "bimb-inspection-mgmt-az3"
  }
}

resource "aws_subnet" "privatesubnetaz1" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.privatecidraz1
  availability_zone = var.az1
  tags = {
    Name = "bimb-inspection-private-az1"
  }
}

resource "aws_subnet" "privatesubnetaz2" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.privatecidraz2
  availability_zone = var.az2
  tags = {
    Name = "bimb-inspection-private-az2"
  }
}

resource "aws_subnet" "privatesubnetaz3" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.privatecidraz3
  availability_zone = var.az3
  tags = {
    Name = "bimb-inspection-private-az3"
  }
}

resource "aws_subnet" "transitsubnetaz1" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.attachcidraz1
  availability_zone = var.az1
  tags = {
    Name = "bimb-inspection-transit-az1"
  }
}

resource "aws_subnet" "transitsubnetaz2" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.attachcidraz2
  availability_zone = var.az2
  tags = {
    Name = "bimb-inspection-transit-az2"
  }
}

resource "aws_subnet" "transitsubnetaz3" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.attachcidraz3
  availability_zone = var.az3
  tags = {
    Name = "bimb-inspection-transit-az3"
  }
}

resource "aws_subnet" "gwlbsubnetaz1" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.gwlbcidraz1
  availability_zone = var.az1
  tags = {
    Name = "bimb-inspection-gqlb-az1"
  }
}

resource "aws_subnet" "gwlbsubnetaz2" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.gwlbcidraz2
  availability_zone = var.az2
  tags = {
    Name = "bimb-inspection-gqlb-az2"
  }
}

resource "aws_subnet" "gwlbsubnetaz3" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.gwlbcidraz3
  availability_zone = var.az3
  tags = {
    Name = "bimb-inspection-gqlb-az3"
  }
}

# S3 endpoint inside the VPC
resource "aws_vpc_endpoint" "s3-endpoint-fgtvm-vpc" {
  count           = var.bucket ? 1 : 0
  vpc_id          = aws_vpc.fgtvm-vpc.id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_route_table.fgtvmmgmtrt.id]
  policy          = <<POLICY
{
    "Statement": [
        {
            "Action": "*",
            "Effect": "Allow",
            "Resource": "*",
            "Principal": "*"
        }
    ]
}
POLICY
  tags = {
    Name = "fgtvm-endpoint-to-s3"
  }
}
