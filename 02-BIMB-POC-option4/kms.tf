############################################################
# KMS KEY — EBS Encryption
############################################################

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "ebs_key" {
  description             = "KMS key for FortiGate EBS volume encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EC2 to use the key for EBS encryption"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name         = "${var.project_name}-ebs-kms-key"
      Project_Name = var.project_name
      Environment  = var.environment
      Department   = "DevOps"
    }
  )
}

resource "aws_kms_alias" "ebs_key_alias" {
  name          = "alias/${var.project_name}-ebs-key"
  target_key_id = aws_kms_key.ebs_key.key_id
}
