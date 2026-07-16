output "resource_share_id" {
value =   aws_ram_resource_share_accepter.receiver_accept.share_id
}

output "resource_share_arn" {
  value = aws_ram_resource_share_accepter.receiver_accept.id
  
}