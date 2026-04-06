output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer. Use this to access the cluster."
  value       = aws_lb.this.dns_name
}

output "alb_url" {
  description = "Full HTTP URL of the Application Load Balancer"
  value       = "http://${aws_lb.this.dns_name}"
}

output "asg_name" {
  description = "Name of the Auto Scaling Group (generated from name_prefix)"
  value       = aws_autoscaling_group.this.name
}

# Additional outputs useful for manual testing

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_sg_id" {
  description = "Security group ID attached to the ALB"
  value       = aws_security_group.alb.id
}

output "instance_sg_id" {
  description = "Security group ID attached to the EC2 instances"
  value       = aws_security_group.instance.id
}

output "target_group_arn" {
  description = "ARN of the ALB target group — use this to verify health check status"
  value       = aws_lb_target_group.this.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic receiving CloudWatch alarm notifications"
  value       = aws_sns_topic.alerts.arn
}

output "cpu_alarm_name" {
  description = "Name of the high-CPU CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
}

output "unhealthy_hosts_alarm_name" {
  description = "Name of the unhealthy hosts CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.unhealthy_hosts.alarm_name
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.this.name
}

# traffic_loop_command

output "traffic_loop_command" {
  description = "Run this in a second terminal to monitor the cluster during deployments"
  value       = "while true; do curl -s http://${aws_lb.this.dns_name}; echo ''; sleep 2; done"
}

# health_check_command

output "health_check_command" {
  description = "Run this after apply to verify all instances are passing ALB health checks"
  value       = "aws elbv2 describe-target-health --target-group-arn ${aws_lb_target_group.this.arn} --query 'TargetHealthDescriptions[*].{ID:Target.Id,State:TargetHealth.State}' --output table"
}
