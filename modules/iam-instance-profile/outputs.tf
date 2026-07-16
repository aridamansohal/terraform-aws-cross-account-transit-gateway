output "instance_profile_name" {
  description = "The name of the IAM instance profile"
  value       = aws_iam_instance_profile.ssm.name
}