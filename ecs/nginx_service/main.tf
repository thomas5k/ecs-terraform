locals {
  name  = "nginx-service"
  image = "nginx"
}

provider "aws" {
  region = var.aws_region
}

##########################################################################################
# Cloudwatch Logs
##########################################################################################
resource "aws_cloudwatch_log_group" "nginx_cloudwatch_logs" {
  name              = "/ecs/${var.vpc_environment}/${local.name}"
  retention_in_days = 1
}

##########################################################################################
# ECS Task 
##########################################################################################
resource "aws_ecs_task_definition" "nginx_task" {
  family = local.name

  container_definitions = <<EOF
[
  {
    "name": "${local.name}",
    "image": "${local.image}",
    "cpu": 0,
    "environment": [
      {
        "name": "APP_ENV",
        "value": "${var.vpc_environment}"
      }
    ],
    "portMappings": [
      {
        "hostPort": 0,
        "protocol": "tcp",
        "containerPort": 80
      }
    ],
    "memory": 128,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${var.aws_region}",
        "awslogs-group": "${aws_cloudwatch_log_group.nginx_cloudwatch_logs.name}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
EOF
}

##########################################################################################
# ECS Service
##########################################################################################
resource "aws_ecs_service" "nginx_service" {
  name            = local.name
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.nginx_task.arn

  desired_count = 1

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
}
