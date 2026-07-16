output "transit_gateway_id" {
  value = module.transit-gateway.transit_gateway_id

}

output "transit_gateway_arn" {
  value = module.transit-gateway.transit_gateway_arn
}
output "vpc_id" {
  value = module.vpc.vpc_id

}

output "private_subnets_ids" {
  value = module.vpc.private_subnets_ids
}

output "public_subnets_ids" {
  value = module.vpc.public_subnets_ids

}

output "resource_share_arn" {
  value = module.ram-share.resource_share_arn

}

output "resource_share_id" {
  value = module.ram-share.resource_share_id
}