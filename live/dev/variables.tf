variable "public_subnets" {
  description = "A list of public subnet CIDR blocks"
  type = map(object({
    cidr_block = string
    az         = string
  }))
}


variable "private_subnets" {
  description = "A list of private subnet CIDR blocks"
  type = map(object({
    cidr_block = string
    az         = string
  }))

}

variable "ec2_instances" {
  type = map(object({
    subnet_key    = string
    instance_type = string
    instance_name = string
  }))
}

variable "instance_type" {

  description = "The CIDR block for the VPC"
  type        = string
  default     = "t2.micro"
}

variable "transit_gateway_name" {
  description = "transit gateway name"
  type        = string
}

variable "allowed_vpc_cidrs" {
  type = map(object({
    cidr        = string
    description = string
  }))
}