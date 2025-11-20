variable "project_name" {
  description = "The name of the project."
  type        = string
  
}

variable "environment" {
  description = "The deployment environment (e.g., development, staging, production)."
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "instance_type" {
  description = "The type of instance to use for the EC2 instances."
  type        = string
}

variable "subnet_az_a" {
  description = "The CIDR block for the subnet in availability zone A."
  type        = string
}

variable "subnet_az_b" {
  description = "The CIDR block for the subnet in availability zone B."
  type        = string
}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instances."
  type        = string
}

