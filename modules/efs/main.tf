terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.4.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_efs_file_system" "efs" {
  creation_token = "TerraformEFSToken"

  tags = {
    Name = "Terraform EFS Project"
  }
}

# Mount target in us-west-2a
resource "aws_efs_mount_target" "mt-az-a" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.subnet_az_a
  security_groups = [var.security_group_ids]
}

# Mount traget in us-west-2b
resource "aws_efs_mount_target" "mt-az-b" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.subnet_az_b
  security_groups = [var.security_group_ids]
}
