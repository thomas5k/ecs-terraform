provider "aws" {
  region = var.aws_region
}

locals {
  name = var.ecs_cluster_name == "" ? "${var.vpc_name}-ecs" : var.ecs_cluster_name
}

################################################################################
# Lookup VPC
################################################################################
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

################################################################################
# Create an ASG using our module
# TODO should this just be the regular resource or community module?
################################################################################
module "aws_asg" {
  source = "../asg"
  vpc_environment = var.vpc_environment
  aws_region = var.aws_region
  vpc_name = var.vpc_name
  additional_tags = [
    {
      key                 = "AmazonECSManaged"
      value               = ""
      propagate_at_launch = true
    }
  ]
}

################################################################################
# Create Service Linked Role for ECS
################################################################################
resource "aws_iam_service_linked_role" "ecs_linked_role" {
  aws_service_name = "ecs.amazonaws.com"
}

################################################################################
# Create a Capacity Provider with our ASG
################################################################################
resource "aws_ecs_capacity_provider" "ecs_provider" {
  depends_on = [module.aws_asg]
  name = local.name

  auto_scaling_group_provider {
    auto_scaling_group_arn = module.aws_asg.this_autoscaling_group_arn
  }
}

################################################################################
# Create ECS Cluster
################################################################################
module "ecs_cluster" {
  source = "terraform-aws-modules/ecs/aws"
  depends_on = [aws_iam_service_linked_role.ecs_linked_role]
  name = local.name
  container_insights = true
  capacity_providers = [aws_ecs_capacity_provider.ecs_provider.name]

  default_capacity_provider_strategy = {
    capacity_provider = aws_ecs_capacity_provider.ecs_provider.name
  }

  tags = {
      Environment = var.vpc_environment
  }
}