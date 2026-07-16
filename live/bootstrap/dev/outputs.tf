output "terraform_role_arn" {

  value = aws_iam_role.terraform_execution.arn
}

output "bucket_arn" {
  value = aws_s3_bucket.terraform_state.arn
}