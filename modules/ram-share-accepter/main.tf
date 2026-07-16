# -----------------------------------------------------------------------------
# Accepts the RAM Share created in the owner account.
#
# The owner account (for example Dev) shares the Transit Gateway using AWS RAM.
# The receiver account (for example Prod) must accept that share before the
# shared Transit Gateway can be used.
# -----------------------------------------------------------------------------

resource "aws_ram_resource_share_accepter" "receiver_accept" {
  # ARN of the RAM Resource Share created in the owner account.
  share_arn = var.resource_share_arn
}