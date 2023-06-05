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
