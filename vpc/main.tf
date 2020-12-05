data "aws_availability_zones" "available" {
  state = "available"
}

################################################################################
# Set up VPC, Subnets, NAT Gateways
################################################################################
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  # just use fist 2 AZs since we're hard-coding 2 subnet cidrs per tier
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_ipv6 = false

  # Disabling NAT Gateways will prevent private EC2s from accessing
  # the internet, but saves the $$ of runnning NAT Gateway instance hours
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = var.vpc_environment
  }

  vpc_tags = {}

  private_subnet_tags = {
    Tier = "private"
  }

  public_subnet_tags = {
    Tier = "public"
  }
}


resource "aws_iam_service_linked_role" "ecs_service_linked_role" {
  aws_service_name = "ecs.amazonaws.com"

  # # TF won't ever be able to delete a service linked role
  # lifecycle {
  #   prevent_destroy = true
  # }
}