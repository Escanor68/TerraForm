output "load_balancer_id" {
  description = "ID del Application Load Balancer"
  value       = aws_lb.main.id
}

output "load_balancer_arn" {
  description = "ARN del Application Load Balancer"
  value       = aws_lb.main.arn
}

output "load_balancer_dns" {
  description = "DNS name del Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "target_group_arn" {
  description = "ARN del Target Group"
  value       = aws_lb_target_group.main.arn
}

output "auto_scaling_group_name" {
  description = "Nombre del Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

