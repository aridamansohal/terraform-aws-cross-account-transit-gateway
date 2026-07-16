data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

module "vpc" {
  source          = "../../modules/vpc"
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  vpc_cidr        = local.vpc_cidrs.prod
  vpc_name        = local.vpc_names.prod

}

module "sg" {
  source            = "../../modules/sg"
  vpc_id            = module.vpc.vpc_id
  allowed_vpc_cidrs = var.allowed_vpc_cidrs
}


module "vpc-endpoint" {
  source              = "../../modules/vpc-endpoint"
  vpc_cidr            = module.vpc.vpc_cidr
  vpc_id              = module.vpc.vpc_id
  region              = local.aws_region
  private_subnets_ids = module.vpc.private_subnets_ids

}

module "iam_instance_profile" {
  source = "../../modules/iam-instance-profile"

}

module "ec2" {
  for_each                  = var.ec2_instances
  source                    = "../../modules/ec2"
  ami_id                    = data.aws_ssm_parameter.amazon_linux_2023.value
  security_group_id         = module.sg.security_group_id
  iam_instance_profile_name = module.iam_instance_profile.instance_profile_name
  instance_type             = each.value.instance_type
  subnet_id                 = module.vpc.private_subnets_ids[each.value.subnet_key]

}

module "transit-gateway-routes" {
  source                  = "../../modules/transit-gateway-routes"
  private_route_table_ids = module.vpc.private_route_table_ids
  destination_cidr_block  = local.vpc_cidrs.dev
  transit_gateway_id      = data.terraform_remote_state.dev.outputs.transit_gateway_id
}

module "tgw-attachment" {
  source              = "../../modules/tgw-attachment"
  transit_gateway_id  = data.terraform_remote_state.dev.outputs.transit_gateway_id
  vpc_id              = module.vpc.vpc_id
  private_subnets_ids = module.vpc.private_subnets_ids

}

module "ram-share-accepter" {
  source             = "../../modules/ram-share-accepter "
  resource_share_arn = data.terraform_remote_state.dev.outputs.resource_share_arn
}