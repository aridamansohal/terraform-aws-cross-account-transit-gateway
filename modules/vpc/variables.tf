variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

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

