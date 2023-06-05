module "rotation_lambda" {
  count   = local.rotation ? 1 : 0
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 2.0"

  function_name = local.name
  handler       = coalesce(var.rotation_lambda_handler, local.default_lambda_handler)
  runtime       = local.lambda_runtime
  timeout       = 120
  tags          = var.tags
  publish       = true
  memory_size   = 128
  layers        = var.rotation_lambda_layers

  vpc_security_group_ids = [module.lambda_security_group[0].security_group_id]
  vpc_subnet_ids         = var.rotation_lambda_subnet_ids
  attach_network_policy  = true

  environment_variables = merge(var.rotation_lambda_env_variables, local.default_lambda_env_vars)

  allowed_triggers = {
    SecretsManager = {
      service = "secretsmanager"
    }
  }

  recreate_missing_package  = var.recreate_missing_package
  role_permissions_boundary = var.role_permissions_boundary

  attach_policy_jsons    = true
  policy_jsons           = local.lambda_policies
  number_of_policy_jsons = length(local.lambda_policies)

  source_path = [
    {
      path             = "${path.module}/functions/${local.function_name}"
      pip_requirements = false
    }
  ]
}
