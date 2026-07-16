variable "transit_gateway_arn" {
  description = "The ARN of the transit gateway"
  type        = string
}

variable "transit_gateway_name" {
  description = "The name of the transit gateway"
  type        = string

}

variable "receiver_account_ids" {
  description = "The account ID of the receiver account"
  type        = map(string)

}

variable "allow_external_principals" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}