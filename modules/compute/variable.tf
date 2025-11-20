variable "instance_type" {
  description = "The type of instance to use for the EC2 instances."
  type = string
}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instances."
  type = string
}

variable "subnet_az_a" {
  description = "The subnet ID for availability zone A."
  type = string
}

variable "subnet_az_b" {
  description = "The subnet ID for availability zone B."
  type = string
}

variable "efs_id" {
  description = "The ID of the EFS file system to mount."
  type = string
}