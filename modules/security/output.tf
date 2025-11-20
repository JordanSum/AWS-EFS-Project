output "security_group_ids" {
    description = "The IDs of the security groups"
    value       = aws_security_group.efs_sg.id
  
}