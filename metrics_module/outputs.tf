output "metrics_endpoint" {
	value = aws_lb.alb_metrics.dns_name
	description = "Load balancer endpoint to the metrics server."
}