variable "private_subnets" {
  type = map(object({
    cidr_block = string
    az         = string
  }))


}

variable "public_subnets" {
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

variable "allowed_vpc_cidrs" {
  type = map(object({
    cidr        = string
    description = string
  }))
}