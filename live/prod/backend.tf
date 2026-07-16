terraform {
  backend "s3" {
    bucket         = "terraform-tgw-prod-state"
    key            = "tgw/prod/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-tgw-prod-locks"
    encrypt        = true
  }
}