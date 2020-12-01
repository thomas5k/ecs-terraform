provider "aws" {
  region = var.aws_region
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
# Look up public subnets
################################################################################
data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.selected.id

  tags = {
    Tier = "public"
  }
}

################################################################################
# Create SG for this ALB allowing all HTTP and Ping traffic in
################################################################################
module "alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"

  name        = "${data.aws_vpc.selected.tags["Name"]}-alb-sg"
  description = "Security group for example usage with ALB"
  vpc_id      = data.aws_vpc.selected.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp"]
  egress_rules        = ["all-all"]
}


################################################################################
# Create the ALB
################################################################################
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"
  
  name = "my-alb"

  load_balancer_type = "application"

  vpc_id             = data.aws_vpc.selected.id
  subnets            = data.aws_subnet_ids.public.ids
  security_groups    = [module.alb_security_group.this_security_group_id]
  
  # access_logs = {
  #   bucket = "my-alb-logs"
  # }

  target_groups = [
    {
      name_prefix      = "http-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      deregistration_delay = 10
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = var.vpc_environment
  }
}