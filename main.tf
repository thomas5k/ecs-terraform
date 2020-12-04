provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./vpc"

  aws_region      = var.aws_region
  vpc_environment = var.vpc_environment
  vpc_name        = var.vpc_name
}

# module "alb" {
#   depends_on = [module.vpc]
#   source     = "./alb"

#   aws_region      = var.aws_region
#   vpc_environment = var.vpc_environment
#   vpc_name        = var.vpc_name
# }

# module "ecs" {
#   depends_on = [module.alb]
#   source     = "./ecs"

#   aws_region      = var.aws_region
#   vpc_environment = var.vpc_environment
#   vpc_name        = var.vpc_name
#   ec2_ssh_key_pub = var.ec2_ssh_key_pub
# }


# module "ec2" {
#   depends_on = [module.vpc]
#   source     = "./ec2"

#   aws_region      = var.aws_region
#   vpc_environment = var.vpc_environment
#   vpc_name        = var.vpc_name
#   ec2_ssh_key_pub = var.ec2_ssh_key_pub
# }
