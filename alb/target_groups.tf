resource "aws_alb_target_group" "nginx_tg" {
  name                 = "${var.vpc_name}-nginx-tg"
  port                 = "8080"
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.selected.id
  deregistration_delay = 100

  health_check {
    path    = "/"
    port    = "8080"
    matcher = "200"
  }

  tags = {
    Name          = "${var.vpc_name}-nginx-tg"
    Environment   = var.vpc_environment
    Terraform     = "true"
    Friendly-Name = "Nginx"
  }
}