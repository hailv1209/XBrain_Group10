resource "aws_secretsmanager_secret" "app_secrets" {
  name                    = "${local.name_prefix}-secrets"
  recovery_window_in_days = 7
  tags                    = { Name = "${local.name_prefix}-secrets" }
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    SECRET_KEY        = "CHANGE_ME_AFTER_DEPLOY"
    API_KEY           = "CHANGE_ME_AFTER_DEPLOY"
    POSTGRES_USER     = "postgres"
    POSTGRES_PASSWORD = "CHANGE_ME_AFTER_DEPLOY"
    REDIS_PASSWORD    = "CHANGE_ME_AFTER_DEPLOY"
    OPENAI_API_KEY    = "CHANGE_ME_AFTER_DEPLOY"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
