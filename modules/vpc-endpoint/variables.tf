variable "region" {
  description = "The AWS region to create resources in"
  type        = string

}

variable "private_subnets_ids" {
  description = "A list of private subnet IDs"
  type        = map(string)

}

variable "vpc_id" {
  description = "The ID of the VPC to create the endpoint in"
  type        = string

}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}