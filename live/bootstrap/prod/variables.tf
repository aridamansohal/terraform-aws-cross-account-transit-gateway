variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
}

variable "aws_access_key" {
  description = "The AWS access key"
  type        = string
}

variable "aws_secret_key" {
  description = "The AWS secret key"
  type        = string
}
variable "terraform_user_arn" {
  description = "The ARN of the Terraform user"
  type        = string
}
variable "state_bucket_name" {}
variable "lock_table_name" {}