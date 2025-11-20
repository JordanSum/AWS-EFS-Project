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

resource "aws_security_group" "efs_sg" {
  name        = "efs-security-group"
  description = "Security group for EFS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }
}