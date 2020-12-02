locals {
  name = "hello-world-service"
  hello_world_image = "hello-world"
}

provider "aws" {
  region = var.aws_region
}

##########################################################################################
# Cloudwatch Logs (hello_world)
##########################################################################################
resource "aws_cloudwatch_log_group" "hello_world" {
  name              = local.name
  retention_in_days = 1
}

##########################################################################################
# ECS Task (hello_world)
##########################################################################################
resource "aws_ecs_task_definition" "hello_world" {
  family = "hello-world"

  container_definitions = <<EOF
[
  {
    "name": "hello-world-task",
    "image": "${local.hello_world_image}",
    "cpu": 0,
    "memory": 128,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${var.aws_region}",
        "awslogs-group": "hello-world",
        "awslogs-stream-prefix": "hello-world"
      }
    }
  }
]
EOF
}

##########################################################################################
# ECS Service (hello_world)
##########################################################################################
resource "aws_ecs_service" "hello_world_service" {
  name            = local.name
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.hello_world.arn

  desired_count = 1

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
}