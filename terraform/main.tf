########################################
# Provider Configuration
########################################
provider "aws" {
  region = "ap-south-1"
}

########################################
# ECR Repository
########################################
resource "aws_ecr_repository" "iris_repo" {
  name         = "iris-ml-repo"
  force_delete = true

  tags = {
    Name = "iris-ml-repo"
  }
}

########################################
# IAM Role for ECS Task Execution
########################################
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

########################################
# VPC and Networking
########################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs_sg"
  description = "Allow inbound traffic for ECS tasks"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs_sg"
  }
}

########################################
# ECS Cluster
########################################
resource "aws_ecs_cluster" "iris_cluster" {
  name = "iris-ml-cluster"

  tags = {
    Name = "iris-ml-cluster"
  }
}

########################################
# ECS Task Definition
########################################
resource "aws_ecs_task_definition" "iris_task" {
  family                   = "iris-ml-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "iris-api-container"
    image     = "${aws_ecr_repository.iris_repo.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]
  }])

  tags = {
    Name = "iris-ml-task"
  }
}

########################################
# ECS Service
########################################
resource "aws_ecs_service" "iris_service" {
  name            = "iris-ml-service"
  cluster         = aws_ecs_cluster.iris_cluster.id
  task_definition = aws_ecs_task_definition.iris_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  tags = {
    Name = "iris-ml-service"
  }
}

########################################
# Outputs
########################################
output "ecr_repo_url" {
  value = aws_ecr_repository.iris_repo.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.iris_cluster.name
}

output "ecs_service_name" {
  value = aws_ecs_service.iris_service.name
}

output "ecs_task_definition_family" {
  value = aws_ecs_task_definition.iris_task.family
}
