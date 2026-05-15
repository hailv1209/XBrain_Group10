output "cloudfront_domain" {
  value       = aws_cloudfront_distribution.main.domain_name
  description = "CloudFront distribution domain"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.main.id
  description = "CloudFront distribution ID (for cache invalidation)"
}

output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "ALB DNS name"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.backend.repository_url
  description = "ECR repository URL for backend image"
}

output "rds_endpoint" {
  value       = aws_rds_cluster.main.endpoint
  description = "RDS cluster endpoint"
}

output "redis_endpoint" {
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
  description = "ElastiCache Redis endpoint"
}

output "frontend_bucket" {
  value       = aws_s3_bucket.frontend.id
  description = "S3 bucket for frontend static files"
}

output "media_bucket" {
  value       = aws_s3_bucket.media.id
  description = "S3 bucket for media files"
}

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "ECS cluster name"
}

output "secrets_arn" {
  value       = aws_secretsmanager_secret.app_secrets.arn
  description = "Secrets Manager ARN"
}
