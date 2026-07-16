### if we run it from dev account then the prod_vpc_cidr if from prod then dev_cpc_cidr


resource "aws_route" "this" {
  for_each               = var.private_route_table_ids
  route_table_id         = each.value
  destination_cidr_block = var.destination_cidr_block
  transit_gateway_id     = var.transit_gateway_id

}

