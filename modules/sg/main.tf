resource "aws_security_group" "allow_icmp" {
  name        = "allow_icmp"
  description = "Allow ICMP inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id

  tags = {
    Name = "allow_icmp"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_icmp_ipv4" {
  for_each          = var.allowed_vpc_cidrs
  security_group_id = aws_security_group.allow_icmp.id
  cidr_ipv4         = each.value.cidr
  description = each.value.description
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_icmp.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

