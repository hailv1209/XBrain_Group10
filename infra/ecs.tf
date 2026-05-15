resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = { Name = "${local.name_prefix}-cluster" }
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${local.name_prefix}-backend"
  retention_in_days = 30
}

# Backend task definition
resource "aws_ecs_task_definition" "backend" {
  family                   = "${local.name_prefix}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name  = "backend"
    image = "${aws_ecr_repository.backend.repository_url}:latest"
    portMappings = [{ containerPort = 8000, protocol = "tcp" }]
    essential = true
    healthCheck = {
      command     = ["CMD-SHELL", "python -c \"import httpx; httpx.get('http://localhost:8000/api/v1/health')\" || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
    environment = [
      { name = "ENVIRONMENT", value = "production" },
      { name = "DEBUG", value = "false" },
      { name = "POSTGRES_HOST", value = aws_rds_cluster.main.endpoint },
      { name = "POSTGRES_PORT", value = "5432" },
      { name = "POSTGRES_DB", value = var.db_name },
      { name = "REDIS_HOST", value = aws_elasticache_replication_group.main.primary_endpoint_address },
      { name = "REDIS_PORT", value = "6379" },
      { name = "S3_REGION", value = var.aws_region },
      { name = "S3_BUCKET", value = aws_s3_bucket.media.id },
      { name = "CORS_ORIGINS", value = jsonencode(["https://${aws_cloudfront_distribution.main.domain_name}"]) },
      { name = "COOKIE_DOMAIN", value = aws_cloudfront_distribution.main.domain_name },
      { name = "COOKIE_SECURE", value = "true" },
    ]
    secrets = [
      { name = "SECRET_KEY", valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:SECRET_KEY::" },
      { name = "API_KEY", valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:API_KEY::" },
      { name = "POSTGRES_USER", valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:POSTGRES_USER::" },
      { name = "POSTGRES_PASSWORD", valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:POSTGRES_PASSWORD::" },
      { name = "REDIS_PASSWORD", valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:REDIS_PASSWORD::" },
      { name = "OPENAI_API_KEY", valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:OPENAI_API_KEY::" },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.backend.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "backend"
      }
    }
  }])
}

# ECS Services
resource "aws_ecs_service" "backend" {
  name            = "${local.name_prefix}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.backend_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_backend.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.http]
}


