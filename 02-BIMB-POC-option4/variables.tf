//AWS Configuration
variable "access_key" {}
variable "secret_key" {}

variable "region" {
  default = "ap-southeast-1"
}

// Availability zones for the region
variable "az1" {
  default = "ap-southeast-1a"
}

variable "az2" {
  default = "ap-southeast-1b"
}

// VPC for FortiGate Security VPC (NS & EW clusters)
variable "vpccidr" {
  default = "172.21.168.0/24"
}

// North-South Cluster Subnets
variable "ns_mgmtcidraz1" {
  default = "172.21.168.0/28"
}

variable "ns_privatecidraz1" {
  default = "172.21.168.16/28"
}

variable "ns_mgmtcidraz2" {
  default = "172.21.168.32/28"
}

variable "ns_privatecidraz2" {
  default = "172.21.168.48/28"
}

// East-West Cluster Subnets
variable "ew_mgmtcidraz1" {
  default = "172.21.168.64/28"
}

variable "ew_privatecidraz1" {
  default = "172.21.168.80/28"
}

variable "ew_attachcidraz1" {
  default = "172.21.168.96/28"
}

variable "ew_gwlbcidraz1" {
  default = "172.21.168.112/28"
}

variable "ew_mgmtcidraz2" {
  default = "172.21.168.128/28"
}

variable "ew_privatecidraz2" {
  default = "172.21.168.144/28"
}

variable "ew_attachcidraz2" {
  default = "172.21.168.160/28"
}

variable "ew_gwlbcidraz2" {
  default = "172.21.168.176/28"
}

// use s3 bucket for bootstrap
// Either true or false
//
variable "bucket" {
  type    = bool
  default = "false"
}

// instance architect
// Either arm or x86
variable "arch" {
  default = "arm"
}

// instance type needs to match the architect
// c5.xlarge is x86_64
// c6g.xlarge is arm
// For detail, refer to https://aws.amazon.com/ec2/instance-types/
variable "size" {
  default = "c6g.xlarge"
}

// License Type to create FortiGate-VM
// Provide the license type for FortiGate-VM Instances, either byol or payg.
variable "license_type" {
  default = "payg"
}

// BYOL License format to create FortiGate-VM
// Provide the license type for FortiGate-VM Instances, file.
variable "license_format" {
  default = "file"
}

// AMIs for FGTVM-7.6.7
variable "fgtami" {
  type = map(any)
  default = {
    ap-southeast-1 = {
      arm = {
        payg = "ami-01a0364907cb53faf"
        byol = "ami-0f8beab3e14825928"
      },
      x86 = {
        byol = "ami-06081b4788006017f"
        payg = "ami-07a0b006b250b393b"
      }
    },
    ap-southeast-2 = {
      arm = {
        payg = "ami-0bad28b6ebd7627eb"
        byol = "ami-0ed3647d8430f38eb"
      },
      x86 = {
        byol = "ami-0451629a1bd0d971e"
        payg = "ami-0a8fb9d197ee75929"
      }
    }
  }
}

// Project name used for resource naming and tagging
variable "project_name" {
  default = "bimb-fgtvm-opt4"
}

// Deployment environment (e.g. dev, staging, prod)
variable "environment" {
  default = "prod"
}

// Common tags applied to all taggable resources
variable "common_tags" {
  type = map(string)
  default = {
    Project     = "bimb-fgtvm-option4"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}

//  Admin HTTPS access port
variable "adminsport" {
  default = "443"
}

variable "bootstrap-fgtvm-ns1" {
  type    = string
  default = "fgtvm-ns1.conf"
}

variable "bootstrap-fgtvm-ns2" {
  type    = string
  default = "fgtvm-ns2.conf"
}

variable "bootstrap-fgtvm-ew1" {
  type    = string
  default = "fgtvm-ew1.conf"
}

variable "bootstrap-fgtvm-ew2" {
  type    = string
  default = "fgtvm-ew2.conf"
}

//license files for the four fgts
variable "licenses" {
  // Change to your own byol license files
  type    = list(string)
  default = ["license-ns1.lic", "license-ns2.lic", "license-ew1.lic", "license-ew2.lic"]
}
