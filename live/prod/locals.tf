locals {

  vpc_names = {
    dev  = "dev-vpc"
    prod = "prod-vpc"
  }

  vpc_cidrs = {
    dev  = "10.0.0.0/16"
    prod = "10.1.0.0/16"
  }

  terraform_role_name = "TerraformExecutionRole"

  account_ids = {
    dev  = "817502249572"
    prod = "031679887831"
  }
  aws_region = "us-west-2"

  terraform_role_arns = {
    dev  = "arn:aws:iam::${local.account_ids.dev}:role/${local.terraform_role_name}"
    prod = "arn:aws:iam::${local.account_ids.prod}:role/${local.terraform_role_name}"
  }

}