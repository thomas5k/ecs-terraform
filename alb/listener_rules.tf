################################################################################
# Listener Rules
################################################################################
resource "aws_alb_listener_rule" "nginx" {
  listener_arn = aws_alb_listener.alb_http_listener.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.nginx_tg.arn
  }

  condition {
    path_pattern {
      values = ["/hello", "/world"]
    }
  }
}