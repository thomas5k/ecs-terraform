locals {
  name  = "nginx-service"
  image = "nginx"

  # We will have to look up the an aws_lb_listener
  # to register our aws_lb_listener_rule against it.
  # This can be done wither by getting the aws_lb name
  # and port, as we do here, or by just getting the
  # aws_lb_listener arn directly.
  lb_name = "${var.vpc_name}-alb"
  lb_port = 80
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

################################################################################
# Look up VPC so we can attach things to it
################################################################################
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}


################################################################################
# Create ALB Target Group
################################################################################
resource "aws_lb_target_group" "nginx_tg" {
  # use name_prefix instead of name to allow modifications
  # via create/destroy
  name_prefix          = "nginx-" 
  port                 = "80"
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.selected.id
  deregistration_delay = 100

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    path    = "/"
    # if ECS task (service?) def is using dynamic port, this fails when we put a port here
    port    = "traffic-port"
    matcher = "200"
  }

  tags = {
    Name          = "${var.vpc_name}-nginx-tg"
    Environment   = var.vpc_environment
    Terraform     = "true"
    Friendly-Name = "Nginx"
  }
}

##### Can we look up the 
##### we need the ALB Listener


data "aws_lb" "vpc_alb" {
  name = local.lb_name
}

data "aws_lb_listener" "lb_listener_80" {
  load_balancer_arn = data.aws_lb.vpc_alb.arn
  port = local.lb_port
}

################################################################################
# Register ALB Listener Rule against one of the VPC's LB Listeners
################################################################################
resource "aws_lb_listener_rule" "nginx" {
  listener_arn = data.aws_lb_listener.lb_listener_80.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_tg.arn
  }

  condition {
    path_pattern {
      values = ["/hello", "/world"]
    }
  }
}


##########################################################################################
# ECS Service
##########################################################################################
resource "aws_ecs_service" "nginx_service" {
  name            = local.name
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.nginx_task.arn

  desired_count = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx_tg.arn
    container_name   = local.name
    container_port   = 80
  }

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
}
