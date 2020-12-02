provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

################################################################################
# Set up VPC, Subnets, NAT Gateways
################################################################################
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name

  cidr = "10.0.0.0/16"

  # just use fist 2 AZs since we're hard-coding 2 subnet cidrs per tier
  azs             = slice(data.aws_availability_zones.available.names, 1, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_ipv6 = false

  # Disabling NAT Gateways will prevent private EC2s from accessing
  # the internet, but saves the $$ of runnning NAT Gateway instance hours
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Owner       = "tom"
    Environment = var.vpc_environment
  }

  vpc_tags = { }

  private_subnet_tags = {
    Tier = "private"
  }

  public_subnet_tags = {
    Tier = "public"
  }

}
