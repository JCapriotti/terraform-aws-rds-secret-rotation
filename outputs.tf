output "default_rotation_lambda_handler" {
  value = local.default_lambda_handler
}

output "rotation_lambda_role_name" {
  value = local.rotation ? module.rotation_lambda[0].lambda_role_name : null
}

output "rotation_lambda_runtime" {
  value = local.lambda_runtime
}

output "secret_arn" {
  value = aws_secretsmanager_secret.this.arn
}

output "secret_name" {
  value = aws_secretsmanager_secret.this.name
}

output "rotation_lambda_security_group_id" {
  value = local.rotation ? module.lambda_security_group[0].security_group_id : null
}
