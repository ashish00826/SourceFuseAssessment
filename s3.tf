//Create an S3 bucket and configure the Terraform to allow the nginx task to write to the S3 bucket

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-nginx-bucket"
  acl    = "private"
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "s3_write_policy" {
  name        = "s3-write-policy"
  description = "Allows writing to the S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = ["s3:PutObject", "s3:PutObjectAcl"],
      Effect   = "Allow",
      Resource = aws_s3_bucket.my_bucket.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_write_attachment" {
  policy_arn = aws_iam_policy.s3_write_policy.arn
  role       = aws_iam_role.ecs_execution_role.name
}

resource "aws_ecs_task_definition" "nginx_task" {
  family                   = "nginx-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name        = "nginx-container"
    image       = "nginx:latest"
    containerPort = 80
    hostPort      = 80
  }])
}

resource "aws_ecs_service" "nginx_service" {
  name            = "nginx-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.nginx_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = ["subnet-0c0a4090415b8dafa"]
    security_groups  = ["sg-09758790c5cae3128"]
  }
}
