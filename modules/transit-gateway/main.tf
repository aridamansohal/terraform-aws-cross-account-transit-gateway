# -----------------------------------------------------------------------------
# Creates a Transit Gateway.
#
# A Transit Gateway acts as a central network router that connects multiple
# VPCs together. Instead of creating many VPC peering connections, each VPC
# creates a single attachment to the Transit Gateway.
#
# In this lab, the Transit Gateway is created in the Dev account and shared
# with the Prod account using AWS RAM.

# Automatically associates new VPC attachments with the default
# Transit Gateway Route Table.
#default_route_table_association = "enable"

# Automatically propagates VPC CIDR routes to the default
# Transit Gateway Route Table.
#default_route_table_propagation = "enable"
# -----------------------------------------------------------------------------

resource "aws_ec2_transit_gateway" "main" {
  auto_accept_shared_attachments = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  tags = {
    Name = "${var.transit_gateway_name}-tgw"
  }
}



