# AWS RDS Secret Rotation

A Terraform module that creates an AWS Secrets Manager secret for RDS, with optional rotation support.

## Features

* Creates secret with the correct format required by RDS.
* Supports PostgreSQL but is easy to add other engines.
* When rotation is enabled, all required infrastructure is created (lambda, security group, etc)

Secret rotation is not only a great thing to do from a security perspective, but it negates the worry about the 
`aws_rds_cluster` resource storing passwords in state.

## Usage

### PostgreSQL Aurora Serverless

```terraform
module "root_user" {
  source = "JCapriotti/rds-secret-rotation"

  db_cluster_identifier = "my-db"
  engine                = "postgres"
  host                  = "my-db.cluster-xxxxxxxx.us-east-1.rds.amazonaws.com"
  name_prefix           = "my-db-"
  port                  = 5432
  username              = "root"
  password              = "SomethingSecret!"
  rotation_days         = 7

  rotation_lambda_subnet_ids = ["subnet-0123456789", "subnet-abcdef0123"]
  rotation_lambda_vpc_id     = "vpc-0123456789"
  db_security_group_id       = aws_security_group.rds.id
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_db_cluster_identifier"></a> [db_cluster_identifier](#input_db_cluster_identifier) | The DB cluster identifier | `string` |  | yes |
| <a name="input_db_security_group_id"></a> [db_security_group_id](#input_db_security_group_id) | The security group ID for the database. Required for secret rotation. | `string` | `null` | no |
| <a name="input_engine"></a> [engine](#input_engine) | The database engine type | `string` |  | yes |
| <a name="input_host"></a> [host](#input_host) | The host name of the database instance | `string` |  | yes |
| <a name="input_master_secret_arn"></a> [master_secret_arn](#input_master_secret_arn) | The superuser credentials used to update another secret in the multiuser rotation strategy. Required when using `multipleuser` rotation strategy. | `string` | null | no |
| <a name="input_name_prefix"></a> [name_prefix](#input_name_prefix) | The prefix for names of created resources. | `string` |  | yes |
| <a name="input_password"></a> [password](#input_password) | The password for the user. | `string` |  | yes |
| <a name="input_port"></a> [port](#input_port) | The port number of the database instance. | `number` |  | yes |
| <a name="input_rotation_days"></a> [rotation_days](#input_rotation_days) | The number of days between rotations. When set to `null` (the default) rotation is not configured. | `number` | `null` | no |
| <a name="input_rotation_lambda_env_variables"></a> [rotation_lambda_env_variables](#input_rotation_lambda_env_variables) | Optional environment variables for the rotation lambda; useful for integration with for certain layer providers. | `map(string)` | `{}` | no |
| <a name="input_rotation_lambda_handler"></a> [rotation_lambda_handler](#input_rotation_lambda_handler) | An optional lambda handler name; useful integration with for certain layer providers. | `string` | `null` | no |
| <a name="input_rotation_lambda_layers"></a> [rotation_lambda_layers](#input_rotation_lambda_layers) | Optional layers for the rotation lambda. | `list(string)` | `null` | no |
| <a name="input_rotation_lambda_policy_jsons"></a> [rotation_lambda_policy_jsons](#input_rotation_lambda_policy_jsons) | Additional policies to add to the rotation lambda; useful for integration with layer providers. | `list(string)` | `[]` | no |
| <a name="input_rotation_lambda_subnet_ids"></a> [rotation_lambda_subnet_ids](#input_rotation_lambda_subnet_ids) | The VPC subnets that the rotation lambda runs in. Required for secret rotation. | `list(string)` | `[]` | no |
| <a name="input_rotation_lambda_vpc_id"></a> [rotation_lambda_vpc_id](#input_rotation_lambda_vpc_id) | The VPC that the secret rotation lambda runs in. Required for secret rotation.  | `string` | null | no |
| <a name="input_rotation_strategy"></a> [rotation_strategy](#input_rotation_strategy) | Specifies how the secret is rotated, either by updating credentials for the user itself (`single`) or by using a superuser's credentials to change another user's credentials (`multiuser`). | `string` | `single` | no |
| <a name="input_secret_recovery_window_days"></a> [secret_recovery_window_days](#input_secret_recovery_window_days) | The number of days that Secrets Manager waits before deleting a secret. | `number` | `0` | no |
| <a name="input_tags"></a> [tags](#input_tags) | Tags to use for created resources. | `map(string)` | `{}` | no |
| <a name="input_username"></a> [username](#input_username) | The username. | `string` |  | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_default_rotation_lambda_handler"></a> [default_rotation_lambda_handler](#output_default_rotation_lambda_handler) | The default lambda handler for the built-in function. Useful for when integrating with a layer. |
| <a name="output_rotation_lambda_role_name"></a> [rotation_lambda_role_name](#output_rotation_lambda_role_name) | The name of the IAM role created for the rotation lambda. |
| <a name="output_rotation_lambda_runtime"></a> [rotation_lambda_runtime](#output_rotation_lambda_runtime) | The runtime of the rotation lambda. |
| <a name="output_rotation_lambda_security_group_id"></a> [rotation_lambda_security_group_id](#output_rotation_lambda_security_group_id) | The security group created for the rotation lambda. |
| <a name="output_secret_arn"></a> [secret_arn](#output_secret_arn) | The ARN of the secret that was created. |
| <a name="output_secret_name"></a> [secret_name](#output_secret_name) | The name of the secret that was created. |
