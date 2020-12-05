provider "aws" {
  region = var.aws_region
}

locals {
  # must be consistent between ASG and ECS calls,
  # as the ASG must be able to register instances with
  # the ECS cluster
  ecs_cluster_name = "${var.vpc_name}-cluster"
}

module "aws_vpc" {
  source = "./vpc"

  aws_region      = var.aws_region
  vpc_environment = var.vpc_environment
  vpc_name        = var.vpc_name
  vpc_cidr        = var.vpc_cidr
  azs             = var.vpc_subnet_mapping["azs"]
  private_subnets = var.vpc_subnet_mapping["private_subnets"]
  public_subnets  = var.vpc_subnet_mapping["public_subnets"]
}

module "aws_alb" {
  depends_on = [module.aws_vpc]
  source     = "./alb"

  aws_region      = var.aws_region
  vpc_environment = var.vpc_environment
  vpc_name        = var.vpc_name
}
module "aws_asg" {
  depends_on       = [module.aws_vpc]
  source           = "./asg"
  vpc_environment  = var.vpc_environment
  aws_region       = var.aws_region
  vpc_name         = var.vpc_name
  ec2_ssh_key_pub  = var.ec2_ssh_key_pub
  azs              = var.vpc_subnet_mapping["azs"]
  private_subnets  = var.vpc_subnet_mapping["private_subnets"]
  public_subnets   = var.vpc_subnet_mapping["public_subnets"]
    ecs_cluster_name = local.ecs_cluster_name

  additional_tags = [
    {
      key                 = "AmazonECSManaged"
      value               = ""
      propagate_at_launch = true
    }
  ]
}

module "aws_ecs" {
  depends_on = [module.aws_alb]
  source     = "./ecs"

  aws_region       = var.aws_region
  vpc_environment  = var.vpc_environment
  vpc_name         = var.vpc_name
  ec2_ssh_key_pub  = var.ec2_ssh_key_pub
  ecs_cluster_name = local.ecs_cluster_name

  autoscaling_group_arn = module.aws_asg.this_autoscaling_group_arn
}


# module "ec2" {
#   depends_on = [module.vpc]
#   source     = "./ec2"

#   aws_region      = var.aws_region
#   vpc_environment = var.vpc_environment
#   vpc_name        = var.vpc_name
#   ec2_ssh_key_pub = var.ec2_ssh_key_pub
# }
