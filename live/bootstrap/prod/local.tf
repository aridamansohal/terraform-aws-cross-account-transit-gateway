locals {
  account_ids = {
    dev  = "817502249572"
    prod = "031679887831"
  }

  terraform_role_name = "TerraformExecutionRole"

  terraform_user_arn = {
    dev  = "arn:aws:iam::${local.account_ids.dev}:user/terraform-bootstrap-admin"
    prod = "arn:aws:iam::${local.account_ids.prod}:user/admin"
  }

  terraform_role_arns = {
    dev  = "arn:aws:iam::${local.account_ids.dev}:role/${local.terraform_role_name}"
    prod = "arn:aws:iam::${local.account_ids.prod}:role/${local.terraform_role_name}"
  }
}