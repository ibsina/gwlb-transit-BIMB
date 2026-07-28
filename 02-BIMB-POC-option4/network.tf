// ========================================
// Route Tables
// ========================================

// North-South Cluster Route Tables
resource "aws_route_table" "ns_mgmtrt" {
  vpc_id = aws_vpc.fgtvm-vpc.id
  tags = {
    Name = "ns-management-rt"
  }
}

resource "aws_route_table" "ns_privatert" {
  vpc_id = aws_vpc.fgtvm-vpc.id
  tags = {
    Name = "ns-private-rt"
  }
}

// East-West Cluster Route Tables
resource "aws_route_table" "ew_mgmtrt" {
  vpc_id = aws_vpc.fgtvm-vpc.id
  tags = {
    Name = "ew-management-rt"
  }
}

resource "aws_route_table" "ew_privatert" {
  vpc_id = aws_vpc.fgtvm-vpc.id
  tags = {
    Name = "ew-private-rt"
  }
}

resource "aws_route_table" "ew_tgwrt" {
  vpc_id = aws_vpc.fgtvm-vpc.id
  tags = {
    Name = "ew-tgw-rt"
  }
}

resource "aws_route_table" "ew_gwlbrt" {
  vpc_id = aws_vpc.fgtvm-vpc.id
  tags = {
    Name = "ew-gwlb-rt"
  }
}

// EW TGW Route to GWLB Endpoint
resource "aws_route" "ew_tgwyroute" {
  depends_on             = [aws_instance.fgtvm_ew1]
  route_table_id         = aws_route_table.ew_tgwrt.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.ew_gwlbendpoint.id
}

// ========================================
// Route Table Associations - North-South
// ========================================

resource "aws_route_table_association" "ns_mgmt_az1" {
  subnet_id      = aws_subnet.ns_mgmtsubnetaz1.id
  route_table_id = aws_route_table.ns_mgmtrt.id
}

resource "aws_route_table_association" "ns_mgmt_az2" {
  subnet_id      = aws_subnet.ns_mgmtsubnetaz2.id
  route_table_id = aws_route_table.ns_mgmtrt.id
}

resource "aws_route_table_association" "ns_private_az1" {
  subnet_id      = aws_subnet.ns_privatesubnetaz1.id
  route_table_id = aws_route_table.ns_privatert.id
}

resource "aws_route_table_association" "ns_private_az2" {
  subnet_id      = aws_subnet.ns_privatesubnetaz2.id
  route_table_id = aws_route_table.ns_privatert.id
}

// ========================================
// Route Table Associations - East-West
// ========================================

resource "aws_route_table_association" "ew_mgmt_az1" {
  subnet_id      = aws_subnet.ew_mgmtsubnetaz1.id
  route_table_id = aws_route_table.ew_mgmtrt.id
}

resource "aws_route_table_association" "ew_mgmt_az2" {
  subnet_id      = aws_subnet.ew_mgmtsubnetaz2.id
  route_table_id = aws_route_table.ew_mgmtrt.id
}

resource "aws_route_table_association" "ew_private_az1" {
  subnet_id      = aws_subnet.ew_privatesubnetaz1.id
  route_table_id = aws_route_table.ew_privatert.id
}

resource "aws_route_table_association" "ew_private_az2" {
  subnet_id      = aws_subnet.ew_privatesubnetaz2.id
  route_table_id = aws_route_table.ew_privatert.id
}

resource "aws_route_table_association" "ew_tgw_az1" {
  subnet_id      = aws_subnet.ew_transitsubnetaz1.id
  route_table_id = aws_route_table.ew_tgwrt.id
}

resource "aws_route_table_association" "ew_tgw_az2" {
  subnet_id      = aws_subnet.ew_transitsubnetaz2.id
  route_table_id = aws_route_table.ew_tgwrt.id
}

resource "aws_route_table_association" "ew_gwlb_az1" {
  subnet_id      = aws_subnet.ew_gwlbsubnetaz1.id
  route_table_id = aws_route_table.ew_gwlbrt.id
}

resource "aws_route_table_association" "ew_gwlb_az2" {
  subnet_id      = aws_subnet.ew_gwlbsubnetaz2.id
  route_table_id = aws_route_table.ew_gwlbrt.id
}

// ========================================
// Security Groups
// ========================================

resource "aws_security_group" "public_allow" {
  name        = "Management Allow"
  description = "Management Allow traffic"
  vpc_id      = aws_vpc.fgtvm-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Management Allow"
  }
}

resource "aws_security_group" "allow_all" {
  name        = "Allow All"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.fgtvm-vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Public Allow"
  }
}

// ========================================
// North-South Gateway Load Balancer (NO Endpoint)
// ========================================

resource "aws_lb" "ns_gateway_lb" {
  name                             = "ns-gwlb${random_string.random_name_post.result}"
  load_balancer_type               = "gateway"
  enable_cross_zone_load_balancing = true

  subnet_mapping {
    subnet_id = aws_subnet.ns_privatesubnetaz1.id
  }

  subnet_mapping {
    subnet_id = aws_subnet.ns_privatesubnetaz2.id
  }
  
  tags = {
    Name = "NS-GWLB"
  }
}

resource "aws_lb_target_group" "ns_fgt_target" {
  name        = "ns-target${random_string.random_name_post.result}"
  port        = 6081
  protocol    = "GENEVE"
  target_type = "ip"
  vpc_id      = aws_vpc.fgtvm-vpc.id

  health_check {
    port     = 8008
    protocol = "TCP"
  }
  
  tags = {
    Name = "NS-Target-Group"
  }
}

resource "aws_lb_listener" "ns_fgt_listener" {
  load_balancer_arn = aws_lb.ns_gateway_lb.id

  default_action {
    target_group_arn = aws_lb_target_group.ns_fgt_target.id
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "ns_fgt1_attach" {
  depends_on       = [aws_instance.fgtvm_ns1]
  target_group_arn = aws_lb_target_group.ns_fgt_target.arn
  target_id        = data.aws_network_interface.ns1_eth1.private_ip
  port             = 6081
}

resource "aws_lb_target_group_attachment" "ns_fgt2_attach" {
  depends_on       = [aws_instance.fgtvm_ns2]
  target_group_arn = aws_lb_target_group.ns_fgt_target.arn
  target_id        = data.aws_network_interface.ns2_eth1.private_ip
  port             = 6081
}

resource "aws_vpc_endpoint_service" "ns_gwlbservice" {
  acceptance_required        = false
  gateway_load_balancer_arns = [aws_lb.ns_gateway_lb.arn]
  
  tags = {
    Name = "NS-GWLB-Service"
  }
}

// ========================================
// East-West Gateway Load Balancer (WITH Endpoint)
// ========================================

resource "aws_lb" "ew_gateway_lb" {
  name                             = "ew-gwlb${random_string.random_name_post.result}"
  load_balancer_type               = "gateway"
  enable_cross_zone_load_balancing = true

  subnet_mapping {
    subnet_id = aws_subnet.ew_privatesubnetaz1.id
  }

  subnet_mapping {
    subnet_id = aws_subnet.ew_privatesubnetaz2.id
  }
  
  tags = {
    Name = "EW-GWLB"
  }
}

resource "aws_lb_target_group" "ew_fgt_target" {
  name        = "ew-target${random_string.random_name_post.result}"
  port        = 6081
  protocol    = "GENEVE"
  target_type = "ip"
  vpc_id      = aws_vpc.fgtvm-vpc.id

  health_check {
    port     = 8008
    protocol = "TCP"
  }
  
  tags = {
    Name = "EW-Target-Group"
  }
}

resource "aws_lb_listener" "ew_fgt_listener" {
  load_balancer_arn = aws_lb.ew_gateway_lb.id

  default_action {
    target_group_arn = aws_lb_target_group.ew_fgt_target.id
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "ew_fgt1_attach" {
  depends_on       = [aws_instance.fgtvm_ew1]
  target_group_arn = aws_lb_target_group.ew_fgt_target.arn
  target_id        = data.aws_network_interface.ew1_eth1.private_ip
  port             = 6081
}

resource "aws_lb_target_group_attachment" "ew_fgt2_attach" {
  depends_on       = [aws_instance.fgtvm_ew2]
  target_group_arn = aws_lb_target_group.ew_fgt_target.arn
  target_id        = data.aws_network_interface.ew2_eth1.private_ip
  port             = 6081
}

resource "aws_vpc_endpoint_service" "ew_gwlbservice" {
  acceptance_required        = false
  gateway_load_balancer_arns = [aws_lb.ew_gateway_lb.arn]
  
  tags = {
    Name = "EW-GWLB-Service"
  }
}

// EW GWLB Endpoints (one per AZ for cross-AZ support)
resource "aws_vpc_endpoint" "ew_gwlbendpoint" {
  service_name      = aws_vpc_endpoint_service.ew_gwlbservice.service_name
  subnet_ids        = [aws_subnet.ew_gwlbsubnetaz1.id, aws_subnet.ew_gwlbsubnetaz2.id]
  vpc_endpoint_type = aws_vpc_endpoint_service.ew_gwlbservice.service_type
  vpc_id            = aws_vpc.fgtvm-vpc.id
  
  tags = {
    Name = "EW-GWLB-Endpoint"
  }
}
