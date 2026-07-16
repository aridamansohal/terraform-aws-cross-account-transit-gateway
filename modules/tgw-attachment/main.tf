# -----------------------------------------------------------------------------
# Attaches the current VPC to the shared Transit Gateway.
#
# This creates the connection between the VPC and the Transit Gateway.
#
# One subnet from each Availability Zone is supplied so AWS can create
# Transit Gateway attachment ENIs in those AZs.
#
# The attachment is created only after the RAM Share accepter has been accepted.
# -----------------------------------------------------------------------------

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  subnet_ids         = values(var.private_subnets_ids)
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = var.vpc_id

}

