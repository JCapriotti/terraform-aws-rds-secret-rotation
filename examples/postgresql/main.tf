provider "aws" {
  region = "us-east-1"
}

locals {
  cluster_name = "aurora-db"
  username     = "root"
  password     = "bar2000!"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.default.id

  filter {
    name   = "tag:Name"
    values = ["Private"]
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "${local.cluster_name}-"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_rds_cluster" "postgresql" {
  cluster_identifier     = local.cluster_name
  engine                 = "aurora-postgresql"
  engine_mode            = "serverless"
  availability_zones     = ["us-east-1a"]
  master_username        = local.username
  master_password        = local.password
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
  scaling_configuration {
    auto_pause               = true
    max_capacity             = 2
    min_capacity             = 2
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }
}

module "root_user" {
  source = "../../"

  db_cluster_identifier = aws_rds_cluster.postgresql.cluster_identifier
  engine                = "postgres"
  host                  = aws_rds_cluster.postgresql.endpoint
  name_prefix           = local.cluster_name
  port                  = aws_rds_cluster.postgresql.port
  username              = local.username
  password              = local.password
  rotation_days         = 1

  rotation_lambda_subnet_ids = data.aws_subnet_ids.private.ids
  rotation_lambda_vpc_id     = data.aws_vpc.default.id
  db_security_group_id       = aws_security_group.rds.id
}
