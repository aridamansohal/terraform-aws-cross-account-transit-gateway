variable "vpc_id" {
  description = "The ID of the VPC to create the security group in"
  type        = string
}

# variable "icmp_cidrs" {
#   description = "The CIDR blocks to allow ICMP traffic from"
#   type        = list(string)
# }

variable "allowed_vpc_cidrs" {
    type = map(object({
        cidr = string
        description = string
    }))
  
}
