variable "private_route_table_ids" {
  description = "A map of private route table IDs"
  type        = map(string)

}

variable "destination_cidr_block" {
  description = "The CIDR block for the destination of the route"
  type        = string
}

variable "transit_gateway_id" {
  description = "The ID of the transit gateway to route traffic through"
  type        = string

}