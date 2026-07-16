locals {
  vpc_endpoint_services = [
    "ssm",
    "ssmmessages",
    "ec2messages"
  ]
}


resource "aws_security_group" "vpc_endpoint_services" {
  name        = "vpc_endpoint_services-sg"
  description = "Allow ec2 to use vpc endpoint services"
  vpc_id      = var.vpc_id

  tags = {
    Name = "vpc_endpoint_services-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_vpc_endpoint_services_ipv4" {
  security_group_id = aws_security_group.vpc_endpoint_services.id
  cidr_ipv4         = var.vpc_cidr
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}


resource "aws_vpc_security_group_egress_rule" "allow_all_vpc_endpoint_services_traffic_ipv4" {
  security_group_id = aws_security_group.vpc_endpoint_services.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



resource "aws_vpc_endpoint" "ec2" {
  for_each          = toset(local.vpc_endpoint_services)
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoint_services.id
  ]
  subnet_ids          = values(var.private_subnets_ids)
  private_dns_enabled = true

}