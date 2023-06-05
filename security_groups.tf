module "lambda_security_group" {
  count   = local.rotation ? 1 : 0
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.3.0"

  name         = local.name
  description  = "Contains egress rules for secret rotation lambda"
  vpc_id       = var.rotation_lambda_vpc_id
  egress_rules = ["https-443-tcp"]

  egress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = var.db_security_group_id
    },
  ]

  tags = merge(var.tags, { Name = local.name })
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
