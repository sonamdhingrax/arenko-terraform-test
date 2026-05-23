resource "aws_security_group" "ecs_sgrp" {
  name        = "${var.environment}-sgrp-web-server"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  egress {
    description = "outbound traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.ecs_sgrp.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb_sgrp.id
}

resource "aws_ecs_cluster" "nginx_cluster" {
  name = "${var.environment}-cluster"
}

data "aws_iam_policy_document" "ecs_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.environment}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_trust.json
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "${var.environment}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_trust.json
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "nginx_log_group" {
  name              = "/aws/ecs/${var.environment}/${var.service}"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "nginx_task" {
  family                   = "${var.service}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu           = "256"
  memory        = "512"
  task_role_arn = aws_iam_role.ecs_task_role.arn

  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = "nginx-container"
    image = "nginx:latest"
    portMappings = [{
      containerPort = 80,
      hostPort      = 80,
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.nginx_log_group.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "nginx"
      }
    }
  }])
}

resource "aws_ecs_service" "nginx_service" {
  name            = "${var.environment}-${var.service}"
  cluster         = aws_ecs_cluster.nginx_cluster.id
  task_definition = aws_ecs_task_definition.nginx_task.arn
  desired_count   = var.environment == "prod" ? length(aws_subnet.private) : 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs_sgrp.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx_target_group.arn
    container_name   = "nginx-container"
    container_port   = 80
  }
}
