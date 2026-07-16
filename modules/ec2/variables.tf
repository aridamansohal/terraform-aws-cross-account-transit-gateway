variable "instance_type" {
  description = "The type of instance to create"
  type        = string

}

variable "ami_id" {
  description = "The AMI ID to use for the instance"
  type        = string

}

variable "subnet_id" {
  description = "The ID of the subnet to launch the instance in"
  type        = string

}

variable "instance_name" {
  description = "The name of the instance"
  type        = string
  default     = ""

}

variable "security_group_id" {
  description = "The ID of the security group to associate with the instance"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "The name of the IAM instance profile to associate with the instance"
  type        = string

}