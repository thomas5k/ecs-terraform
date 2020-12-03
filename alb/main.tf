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
# Create Security Group for ALB
################################################################################
resource "aws_security_group" "alb_sg" {
  name        = "${var.vpc_name}-alb-sg"
  description = "Allow 80 and 443 into LB."
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.vpc_name}-alb-sg"
    Environment = var.vpc_environment
    Terraform   = "true"
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
# Create actual ALB
################################################################################
resource "aws_alb" "alb" {
  name               = "${var.vpc_name}-alb"
  idle_timeout       = 1000
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnet_ids.public.ids

  # access_logs {
  #   # TODO by pod?
  #   bucket  = "${var.aws_s3_alb_log_bucket}"
  #   prefix  = "${var.environment}-alb-logs"
  #   enabled = true
  # }

  tags = {
    Name        = "${var.vpc_name}-alb"
    Environment = var.vpc_environment
    Terraform   = "true"
  }
}

################################################################################
# ALB Listener (Port 80)
################################################################################
resource "aws_alb_listener" "alb_http_listener" {
  load_balancer_arn = aws_alb.alb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Normally we'd have a redirect or actual TG forward here, but I want to test explicit tgs separate from the default action."
      status_code  = "200"
    }
  }
}
