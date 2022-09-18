locals {
  rotation               = var.rotation_days == null ? false : true
  function_name          = var.rotation_strategy == "single" ? "postgresql-single-user" : "postgresql-multiuser"
  default_lambda_handler = "lambda_function.lambda_handler"
  lambda_runtime         = "python3.7"
  name                   = "${var.name_prefix}-${var.username}-rotate-secret"

  secret_value_single_user = {
    username            = var.username
    password            = var.password
    engine              = var.engine
    host                = var.host
    port                = var.port
    dbClusterIdentifier = var.db_cluster_identifier
  }
  secret_value_multiuser = {
    username            = var.username
    password            = var.password
    engine              = var.engine
    host                = var.host
    port                = var.port
    masterarn           = var.master_secret_arn
    dbClusterIdentifier = var.db_cluster_identifier
  }

  default_lambda_env_vars = {
    SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${data.aws_region.current.name}.amazonaws.com"
  }
}

data "aws_region" "current" {}

resource "aws_secretsmanager_secret" "this" {
  name                    = "${var.name_prefix}-${var.username}"
  recovery_window_in_days = var.secret_recovery_window_days
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id      = aws_secretsmanager_secret.this.id
  secret_string  = jsonencode(var.rotation_strategy == "single" ? local.secret_value_single_user : local.secret_value_multiuser)

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


module "lambda_security_group" {
  count   = local.rotation ? 1 : 0
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.3.0"

  name          = local.name
  description   = "Contains egress rules for secret rotation lambda"
  vpc_id        = var.rotation_lambda_vpc_id
  egress_rules  = ["https-443-tcp"]

  egress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = var.db_security_group_id
    },
  ]

  tags = merge(var.tags, {Name = local.name})
}

module "db_ingress" {
  count   = local.rotation ? 1 : 0
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.3.0"

  create_sg         = false
  security_group_id = var.db_security_group_id
  ingress_with_source_security_group_id = [
    {
      description              = "Secret rotation lambda"
      rule                     = "postgresql-tcp"
      source_security_group_id = module.lambda_security_group[0].security_group_id
    },
  ]
}

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
      service    = "secretsmanager"
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

locals {
  lambda_policies = flatten([
    data.aws_iam_policy_document.superuser[*].json,
    data.aws_iam_policy_document.secret.json,
    var.rotation_lambda_policy_jsons,
  ])
}

data "aws_iam_policy_document" "secret" {
  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage",
    ]
    resources = [
      aws_secretsmanager_secret.this.arn,
    ]
  }
  statement {
    actions = [
      "secretsmanager:GetRandomPassword",
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "superuser" {
  count = var.rotation_strategy == "single" ? 0 : 1
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      var.master_secret_arn,
    ]
  }
}
