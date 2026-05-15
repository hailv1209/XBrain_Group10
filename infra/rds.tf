resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet"
  subnet_ids = aws_subnet.private[*].id
  tags       = { Name = "${local.name_prefix}-db-subnet" }
}

resource "aws_rds_cluster" "main" {
  cluster_identifier        = "${local.name_prefix}-db"
  engine                    = "aurora-postgresql"
  engine_version            = "16.4"
  engine_mode               = "provisioned"
  database_name             = var.db_name
  master_username           = "postgres"
  master_password           = jsondecode(aws_secretsmanager_secret_version.app_secrets.secret_string)["POSTGRES_PASSWORD"]
  db_subnet_group_name      = aws_db_subnet_group.main.name
  vpc_security_group_ids    = [aws_security_group.rds.id]
  skip_final_snapshot       = false
  final_snapshot_identifier = "${local.name_prefix}-db-final"
  storage_encrypted         = true

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 2
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = { Name = "${local.name_prefix}-db" }
}

resource "aws_rds_cluster_instance" "main" {
  identifier          = "${local.name_prefix}-db-instance"
  cluster_identifier  = aws_rds_cluster.main.id
  instance_class      = "db.serverless"
  engine              = aws_rds_cluster.main.engine
  engine_version      = aws_rds_cluster.main.engine_version
  publicly_accessible = false

  tags = { Name = "${local.name_prefix}-db-instance" }
}
