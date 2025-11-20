variable "subnet_az_a" {
  description = "The subnet ID for availability zone A."
  type = string
}

variable "subnet_az_b" {
  description = "The subnet ID for availability zone B."
  type = string
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with the EFS."
  type = string
}