// FGTVM North-South Cluster - Instance 2 (AZ2)

resource "aws_network_interface" "ns2_eth0" {
  description = "fgtvm-ns2-port1"
  subnet_id   = aws_subnet.ns_mgmtsubnetaz2.id
}

resource "aws_network_interface" "ns2_eth1" {
  description       = "fgtvm-ns2-port2"
  subnet_id         = aws_subnet.ns_privatesubnetaz2.id
  source_dest_check = false
}

data "aws_network_interface" "ns2_eth1" {
  id = aws_network_interface.ns2_eth1.id
}

// Get GWLB Endpoint IP for NS Cluster AZ2
data "aws_network_interface" "ns_vpcendpointip_az2" {
  id = tolist(aws_vpc_endpoint.ns_gwlbendpoint_az2.network_interface_ids)[0]
}

resource "aws_network_interface_sg_attachment" "ns2_public_attachment" {
  depends_on           = [aws_network_interface.ns2_eth0]
  security_group_id    = aws_security_group.public_allow.id
  network_interface_id = aws_network_interface.ns2_eth0.id
}

resource "aws_network_interface_sg_attachment" "ns2_internal_attachment" {
  depends_on           = [aws_network_interface.ns2_eth1]
  security_group_id    = aws_security_group.allow_all.id
  network_interface_id = aws_network_interface.ns2_eth1.id
}

# Cloudinit config in MIME format
data "cloudinit_config" "config_ns2" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "license"
    content_type = "text/plain"
    content      = var.license_format == "token" ? "LICENSE-TOKEN:${chomp(file("${var.licenses[1]}"))} INTERVAL:4 COUNT:4" : "${file("${var.licenses[1]}")}"
  }

  part {
    filename     = "config"
    content_type = "text/x-shellscript"
    content = templatefile("${var.bootstrap-fgtvm-ns2}", {
      adminsport  = "${var.adminsport}"
      dst         = var.ns_privatecidraz1
      gateway     = cidrhost(var.ns_privatecidraz2, 1)
      endpointip  = "${data.aws_network_interface.ns_vpcendpointip_az1.private_ip}"
      endpointip2 = "${data.aws_network_interface.ns_vpcendpointip_az2.private_ip}"
    })
  }
}

resource "aws_instance" "fgtvm_ns2" {
  ami               = var.fgtami[var.region][var.arch][var.license_type]
  instance_type     = var.size
  availability_zone = var.az2
  key_name          = aws_key_pair.ec2_key_pair.key_name

  user_data = var.bucket ? (var.license_format == "file" ? "${jsonencode({ bucket = aws_s3_bucket.s3_bucket[0].id,
    region                        = var.region,
    license                       = var.licenses[1],
    config                        = "${var.bootstrap-fgtvm-ns2}"
    })}" : "${jsonencode({ bucket = aws_s3_bucket.s3_bucket[0].id,
    region                        = var.region,
    license-token                 = file("${var.licenses[1]}"),
    config                        = "${var.bootstrap-fgtvm-ns2}"
  })}") : "${data.cloudinit_config.config_ns2.rendered}"

  iam_instance_profile = var.bucket ? aws_iam_instance_profile.fortigate[0].id : ""

  root_block_device {
    volume_type           = "gp3"
    volume_size           = "2"
    encrypted             = true
    delete_on_termination = true
    kms_key_id            = aws_kms_key.ebs_key.arn
  }

  ebs_block_device {
    device_name           = "/dev/sdb"
    volume_size           = "30"
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
    kms_key_id            = aws_kms_key.ebs_key.arn
  }

  primary_network_interface {
    network_interface_id = aws_network_interface.ns2_eth0.id
  }

  tags = merge(var.common_tags, {
    Name = "FortiGate-NS2"
  })
}

resource "aws_network_interface_attachment" "ns2_eth1_attach" {
  instance_id          = aws_instance.fgtvm_ns2.id
  network_interface_id = aws_network_interface.ns2_eth1.id
  device_index         = 1
}
