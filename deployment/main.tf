provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "this" {
  name = "akka-app-cluster"
  tags = {
    Project = "aipcc-akka"
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
  tags = {
    Project = "aipcc-akka"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_security_group" "akka_sg" {
  name        = "akka-internal-sg"
  description = "Allow internal access to ECS task on port 5000"
  vpc_id      = "vpc-0ff68e46a55526721"

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Project = "aipcc-akka"
  }
}

resource "aws_ecs_task_definition" "akka_app" {
  family                   = "akka-app-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "akka-app"
      image     = "images.paas.redhat.com/rhel-ai-cicd/akka:latest"
      portMappings = [
        {
          containerPort = 5000,
          protocol      = "tcp"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/akka-app",
          awslogs-region        = "us-east-1",
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
  tags = {
    Project = "aipcc-akka"
  }
}

resource "aws_cloudwatch_log_group" "ecs_log" {
  name              = "/ecs/akka-app"
  retention_in_days = 7
  tags = {
    Project = "aipcc-akka"
  }
}

resource "aws_ecs_service" "akka_app" {
  name            = "akka-app-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.akka_app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = ["subnet-0796750adde04eb9e"]
    security_groups  = [aws_security_group.akka_sg.id]
    assign_public_ip = false
  }
  propagate_tags = "TASK_DEFINITION"
  tags = {
    Project = "aipcc-akka"
  }
}

