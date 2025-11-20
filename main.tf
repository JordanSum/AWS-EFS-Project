terraform {
    required_version = ">= 1.0.0"
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 6.4.0"
      }
    }
}

provider "aws" {
  region = "us-west-2"
}

module "network" {
    source = "./modules/network"
    cidr_block = var.cidr_block
    project_name = var.project_name
    environment = var.environment
    subnet_az_a = var.subnet_az_a
    subnet_az_b = var.subnet_az_b
}

module "compute" {
    source = "./modules/compute"
    ami_id = var.ami_id
    instance_type = var.instance_type
    subnet_az_a = module.network.subnet_az_a
    subnet_az_b = module.network.subnet_az_b
    efs_id = module.efs.efs_id

}

module "security" {
    source = "./modules/security"
    vpc_id = module.network.vpc
    cidr_block = var.cidr_block
}

module "efs" {
    source = "./modules/efs"
    subnet_az_a = module.network.subnet_az_a
    subnet_az_b = module.network.subnet_az_b
    security_group_ids = module.security.security_group_ids
}