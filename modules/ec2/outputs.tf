output "ec2_arn" {
  description = "The ARN of the EC2 instance"
  value       = aws_instance.main.arn

}

output "ec2_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.main.id
}
