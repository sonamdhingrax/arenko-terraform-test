# resource "aws_ecs_cluster" "nginx_cluster" {
#   name = "${var.environment}-cluster"
# }

# resource "aws_ecs_task_definition" "nginx_task" {
#   family                   = "nginx-task"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]

#   cpu           = "256"
#   memory        = "512"
#   task_role_arn = aws_iam_role.ecs_task_role.arn

#   execution_role_arn = aws_iam_role.execution_role.arn

#   container_definitions = jsonencode([{
#     name  = "nginx-container"
#     image = "nginx:latest"
#     portMappings = [{
#       containerPort = 80,
#       hostPort      = 80,
#     }]
#   }])
# }

# resource "aws_iam_role" "ecs_task_role" {
#   name = "ecs-task-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Action = "sts:AssumeRole",
#       Effect = "Allow",
#       Principal = {
#         Service = "ecs-tasks.amazonaws.com"
#       }
#     }]
#   })
# }

# resource "aws_iam_role" "ecs_execution_role" {
#   name = "ecs-execution-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Action = "sts:AssumeRole",
#       Effect = "Allow",
#       Principal = {
#         Service = "ecs-tasks.amazonaws.com"
#       }
#     }]
#   })
# }

# resource "aws_ecs_service" "nginx_service" {
#   name            = "${var.environment}-${var.service}"
#   cluster         = aws_ecs_cluster.nginx_cluster.id
#   task_definition = aws_ecs_task_definition.nginx_task.arn
#   launch_type     = "FARGATE"

#   network_configuration {
#     subnets         = [aws_subnet.web-1.id]
#     security_groups = [aws_security_group.ecs-sgrp.id]
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.nginx_target_group.arn
#     container_name   = "nginx-container"
#     container_port   = 81
#   }

#   depends_on = [aws_ecs_task_definition.nginx_task]
# }

# resource "aws_security_group" "ecs-sgrp" {
#   name        = "sgrp-web-server"
#   description = "Allow HTTP inbound traffic"
#   vpc_id      = aws_vpc.vpc.id

#   egress {
#     description = "outbound traffic"
#     from_port   = 0
#     to_port     = 65535
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "database-sgrp" {
#   name        = "sgrp-database"
#   description = "Allow inbound traffic from application security group"
#   vpc_id      = aws_vpc.vpc.id

#   ingress {
#     description = "Allow traffic from application layer"
#     from_port   = 3306
#     to_port     = 3306
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

# }

# resource "aws_db_instance" "rds" {
#   allocated_storage      = 10
#   db_subnet_group_name   = aws_db_subnet_group.subnet_group.id
#   engine                 = "postgres"
#   engine_version         = "postgres13"
#   instance_class         = "db.t2.micro"
#   multi_az               = true
#   name                   = "mydb"
#   username               = "username"
#   password               = "password"
#   skip_final_snapshot    = true
#   vpc_security_group_ids = [aws_security_group.database-sgrp.id]
# }

# resource "aws_db_subnet_group" "subnet_group" {
#   name       = "main"
#   subnet_ids = [aws_subnet.public-1.id, aws_subnet.public-2.id]

# }
