resource "aws_security_group" "alb_sgrp" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for Public facing ALB"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "Allow HTTP traffic from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTPS traffic from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs_egress" {
  security_group_id            = aws_security_group.alb_sgrp.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_sgrp.id
}

resource "aws_lb" "nginx_alb" {
  name               = "${var.service}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.alb_sgrp.id]

  enable_deletion_protection = true

  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.environment}-alb"
  }
}

resource "aws_lb_target_group" "nginx_target_group" {
  name        = "${var.service}-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    path = "/"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "nginx_listener_http" {
  load_balancer_arn = aws_lb.nginx_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_target_group.arn
  }
}

# resource "aws_lb_target_group_attachment" "nginx_target_group_attachment" {
#   target_group_arn = aws_lb_target_group.nginx_target_group.arn
#   target_id        = aws_ecs_service.nginx_service.name
# }
