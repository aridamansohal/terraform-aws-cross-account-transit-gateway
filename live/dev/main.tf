data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

module "vpc" {
  source         = "../../modules/vpc"
  vpc_cidr       = local.vpc_cidrs.dev
  vpc_name       = local.vpc_names.dev
  public_subnets = var.public_subnets

  private_subnets = var.private_subnets

}

module "vpc-endpoint" {
  source              = "../../modules/vpc-endpoint"
  private_subnets_ids = module.vpc.private_subnets_ids
  region              = local.aws_region
  vpc_id              = module.vpc.vpc_id
  vpc_cidr            = module.vpc.vpc_cidr
}
module "sg" {
  source            = "../../modules/sg"
  vpc_id            = module.vpc.vpc_id
  allowed_vpc_cidrs = var.allowed_vpc_cidrs
}

module "iam_instance_profile" {
  source = "../../modules/iam-instance-profile"

}

module "ec2" {
  for_each                  = var.ec2_instances
  source                    = "../../modules/ec2"
  instance_type             = var.instance_type
  ami_id                    = data.aws_ssm_parameter.amazon_linux_2023.value
  subnet_id                 = module.vpc.private_subnets_ids[each.value.subnet_key]
  security_group_id         = module.sg.security_group_id
  iam_instance_profile_name = module.iam_instance_profile.instance_profile_name

}


module "transit-gateway" {
  source               = "../../modules/transit-gateway"
  transit_gateway_name = "${var.transit_gateway_name}-tgw"

}

module "tgw-attachment" {
  source              = "../../modules/tgw-attachment"
  private_subnets_ids = module.vpc.private_subnets_ids
  transit_gateway_id  = module.transit-gateway.transit_gateway_id
  vpc_id              = module.vpc.vpc_id


}

module "ram-share" {


  # receiver_account_ids expects a map(string), NOT a single string.
  #
  # ❌ Wrong:
  # receiver_account_ids = local.account_ids.prod
  # Result:
  # "031679887831" (string)
  #
  # ✅ Correct:
  # receiver_account_ids = local.tgw_share_receivers
  # Result:
  # {
  #   prod = "031679887831"
  # }
  #
  # This keeps the module reusable. To share the TGW with additional AWS accounts
  # in the future (QA, Shared Services, Management, etc.), simply add them to
  # local.tgw_share_receivers without changing the module code.


  source               = "../../modules/ram-share"
  receiver_account_ids = local.tgw_share_receivers
  transit_gateway_arn  = module.transit-gateway.transit_gateway_arn
  transit_gateway_name = "${var.transit_gateway_name}-tgw"

}



module "transit-gateway_routes" {
  source                  = "../../modules/transit-gateway-routes"
  destination_cidr_block  = local.vpc_cidrs.prod
  private_route_table_ids = module.vpc.private_route_table_ids
  transit_gateway_id      = module.transit-gateway.transit_gateway_id
  depends_on = [
    module.transit-gateway
  ]
}



