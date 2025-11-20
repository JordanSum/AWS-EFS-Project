variable "vpc_id" {
    description = "The VPC ID where the security group will be created."
    type        = string
}

variable "cidr_block" {
    description = "The CIDR block to allow access to the security group."
    type        = string
}