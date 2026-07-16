data "terraform_remote_state" "dev" {
  backend = "s3"

  config = {
    bucket = "terraform-tgw-dev-state"
    key    = "tgw/dev/terraform.tfstate"
    region = "us-west-2"
  }
}