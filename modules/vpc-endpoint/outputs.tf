output "ssm_endpoint_id" {
  description = "Map of VPC Endpoint IDs"
  value       =  {for k, v in aws_vpc_endpoint.ec2 :
  k=>v.id }

}