output "load_balancer_dns_name" {
    value = "http://${aws_lb.load_balancer.dns_name}"
}