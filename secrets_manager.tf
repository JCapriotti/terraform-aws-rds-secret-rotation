resource "aws_secretsmanager_secret" "this" {
  name                    = "${var.name_prefix}-${var.username}"
  recovery_window_in_days = var.secret_recovery_window_days
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = jsonencode(var.rotation_strategy == "single" ? local.secret_value_single_user : local.secret_value_multiuser)

  lifecycle {
    ignore_changes = [
      secret_string,
      version_stages
    ]
  }
}

resource "aws_secretsmanager_secret_rotation" "this" {
  count = local.rotation ? 1 : 0

  rotation_lambda_arn = module.rotation_lambda.0.lambda_function_arn
  secret_id           = aws_secretsmanager_secret.this.id

  rotation_rules {
    automatically_after_days = var.rotation_days
  }

  depends_on = [aws_secretsmanager_secret_version.this]
}
