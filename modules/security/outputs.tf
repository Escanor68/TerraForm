output "alb_security_group_id" {
  description = "ID del Security Group del ALB"
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "ID del Security Group de EC2"
  value       = aws_security_group.ec2.id
}

output "ec2_role_arn" {
  description = "ARN del rol IAM para EC2"
  value       = aws_iam_role.ec2.arn
}

output "ec2_instance_profile_name" {
  description = "Nombre del Instance Profile para EC2"
  value       = aws_iam_instance_profile.ec2.name
}

