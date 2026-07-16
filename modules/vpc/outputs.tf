# -----------------------------------------------------------------------------
# Understanding this output
#
# Output:
#
# output "private_route_table_ids" {
#   value = {
#     for k, v in aws_route_table.private :
#     k => v.id
#   }
# }
#
# -----------------------------------------------------------------------------
# STEP 1
#
# aws_route_table.private was created using for_each.
#
# Example:
#
# resource "aws_route_table" "private" {
#   for_each = aws_subnet.private
# }
#
# Suppose Terraform created two route tables.
#
# Terraform internally stores them like this:
#
# aws_route_table.private = {
#
#   private_route_table_a = {
#       id  = "rtb-111"
#       arn = "arn:aws:..."
#       tags = {...}
#       ...
#   }
#
#   private_route_table_b = {
#       id  = "rtb-222"
#       arn = "arn:aws:..."
#       tags = {...}
#       ...
#   }
# }
#
# IMPORTANT:
#
# The VALUE is NOT the Route Table ID.
#
# The VALUE is the ENTIRE Route Table resource object.
#
#
# -----------------------------------------------------------------------------
# STEP 2 (Iteration 1)
#
# k =
#
# private_route_table_a
#
# v =
#
# {
#    id  = "rtb-111"
#    arn = "arn:aws:..."
#    tags = {...}
#    ...
# }
#
# Think of v as:
#
# "Current Route Table Object"
#
#
# -----------------------------------------------------------------------------
# STEP 3
#
# Now Terraform evaluates:
#
# k => v.id
#
# Left side (k)
#
# private_route_table_a
#
# becomes the NEW KEY.
#
#
# Right side (v.id)
#
# rtb-111
#
# becomes the NEW VALUE.
#
#
# Terraform creates:
#
# private_route_table_a = "rtb-111"
#
#
# -----------------------------------------------------------------------------
# STEP 4 (Iteration 2)
#
# k =
#
# private_route_table_b
#
# v =
#
# {
#    id  = "rtb-222"
#    arn = "arn:aws:..."
#    ...
# }
#
# Again,
#
# k => v.id
#
# becomes
#
# private_route_table_b = "rtb-222"
#
#
# -----------------------------------------------------------------------------
# FINAL RESULT
#
# {
#   private_route_table_a = "rtb-111"
#   private_route_table_b = "rtb-222"
# }
#
#
# -----------------------------------------------------------------------------
# SIMPLE WAY TO REMEMBER
#
# k = Current Resource Name
#
# v = Current Resource Object
#
# v.id = Current Resource ID
#
# v.arn = Current Resource ARN
#
# v.tags = Current Resource Tags
#
#
# k => v.id
#
# simply means:
#
# "Create a NEW map where
#
#  the KEY is the Route Table Name
#
#  and the VALUE is the Route Table ID."
#
# Think of "=>" as:
#
# NEW_KEY => NEW_VALUE
#
# NOT
#
# OLD_KEY => OLD_VALUE
#
# We are transforming one map into another map.
# -----------------------------------------------------------------------------



output "vpc_name" {
  description = "The name of the VPC"
  value       = aws_vpc.main.tags["Name"]

}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id

}

output "public_subnets_ids" {
  value = { for subnet_name, subnet in aws_subnet.public : subnet_name => subnet.id }

}

output "private_subnets_ids" {
  value = { for subnet_name, subnet in aws_subnet.private : subnet_name => subnet.id }

}

output "public_route_ids" {
  value = { for k, v in aws_route_table.public :
  k => v.id }

}

output "private_route_table_ids" {
  value = { for k, v in aws_route_table.private :
  k => v.id }

}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block

}