locals {
  name = var.ecs_cluster_name
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

resource "aws_iam_service_linked_role" "ecs_service_linked_role" {
  aws_service_name = "ecs.amazonaws.com"

  # # TF won't ever be able to delete a service linked role
  # lifecycle {
  #   prevent_destroy = true
  # }
}

################################################################################
# Create a Capacity Provider with our ASG
################################################################################
resource "aws_ecs_capacity_provider" "ecs_provider" {
  name = local.name

  auto_scaling_group_provider {
    auto_scaling_group_arn = var.autoscaling_group_arn

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 1
    }
  }

  tags = {
    Environment = var.vpc_environment
  }
}

################################################################################
# Create the ECS Cluster
################################################################################
resource "aws_ecs_cluster" "this" {
  name = local.name

  capacity_providers = [aws_ecs_capacity_provider.ecs_provider.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_provider.name
    weight            = 1
  }

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    Environment = var.vpc_environment
  }
}

module "nginx_service" {
  source = "./nginx_service"

  vpc_environment = var.vpc_environment
  aws_region      = var.aws_region
  vpc_name        = var.vpc_name
  ecs_cluster_id  = aws_ecs_cluster.this.id
}
