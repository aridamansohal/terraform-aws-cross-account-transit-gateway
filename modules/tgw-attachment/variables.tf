variable "vpc_id" {
  description = "The ID of the VPC to attach to the transit gateway"
  type        = string
}

variable "private_subnets_ids" {
  description = "A list of private subnet IDs to attach to the transit gateway"
  type        = map(string)
}



variable "transit_gateway_id" {
  description = "The ID of the transit gateway to attach to the VPC"
  type        = string

}