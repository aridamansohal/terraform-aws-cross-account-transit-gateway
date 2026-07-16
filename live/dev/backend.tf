terraform {
  backend "s3" {
    bucket         = "terraform-tgw-dev-state"
    key            = "tgw/dev/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-tgw-dev-locks"
    encrypt        = true
  }
}
