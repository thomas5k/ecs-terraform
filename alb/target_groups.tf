resource "aws_alb_target_group" "nginx_tg" {
  name                 = "${var.vpc_name}-nginx-tg"
  port                 = "8080"
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.selected.id
  deregistration_delay = 100

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