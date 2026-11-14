output "alb_dns_name" {
  value       = aws_lb.app.dns_name
  description = "Open http://<this>/ in a browser (Phase 02 live URL)"
}

output "alb_url" {
  value = "http://${aws_lb.app.dns_name}"
}

output "data_private_ip" {
  value       = aws_instance.data.private_ip
  description = "App compose points Mongo/Redis/Rabbit here"
}

output "data_instance_id" {
  value = aws_instance.data.id
}

output "asg_name" {
  value = aws_autoscaling_group.app.name
}

output "ecr_repository_urls" {
  value = { for k, r in aws_ecr_repository.app : k => r.repository_url }
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "Set GitHub Actions secret AWS_ROLE_ARN to this value"
}

output "aws_region" {
  value = var.aws_region
}
