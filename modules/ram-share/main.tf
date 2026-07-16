# -----------------------------------------------------------------------------
# Creates a RAM Resource Share.
#
# This acts as a container that will be used to share AWS resources
# (Transit Gateway in our case) with other AWS accounts.
# -----------------------------------------------------------------------------

resource "aws_ram_resource_share" "main" {
  name                      = "${var.transit_gateway_name}-share"
  allow_external_principals = var.allow_external_principals

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Associates the Transit Gateway with the RAM Resource Share.
#
# Without this association, the RAM Share exists but does not contain
# any resources to share.
# -----------------------------------------------------------------------------


resource "aws_ram_resource_association" "main" {
  resource_arn       = var.transit_gateway_arn
  resource_share_arn = aws_ram_resource_share.main.arn

}

# -----------------------------------------------------------------------------
# Shares the RAM Resource Share with one or more AWS accounts.
#
# receiver_account_ids is a map, allowing us to share the Transit Gateway
# with multiple accounts (Dev, Prod, QA, etc.) using for_each.
#
# Example:
# receiver_account_ids = {
#   prod = "222222222222"
#   qa   = "333333333333"
# }
# -----------------------------------------------------------------------------

resource "aws_ram_principal_association" "main" {
  for_each           = var.receiver_account_ids
  principal          = each.value
  resource_share_arn = aws_ram_resource_share.main.arn
}



