# -------------------------------------------------------
# live/outputs.tf
# -------------------------------------------------------

output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
}

output "alb_url" {
  value = module.webserver_cluster.alb_url
}

output "asg_name" {
  value = module.webserver_cluster.asg_name
}

output "health_check_command" {
  value = module.webserver_cluster.health_check_command
}

output "traffic_loop_command" {
  value = module.webserver_cluster.traffic_loop_command
}
