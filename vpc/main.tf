provider "aws" {
  region = "us-east-2"
}

################################################################################
# Set up VPC, Subnets, NAT Gateways
################################################################################
module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v2.64.0"

	name = "pg-sandbox"

  cidr = "10.0.0.0/16"

  azs             = ["us-east-2a", "us-east-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_ipv6 = false

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Owner       = "tom"
    Environment = "dev"
  }

  vpc_tags = { }
}
