//Provision an ECS cluster and load balancer

provider "aws" {
  region = "us-east-1"  # Change this to your desired AWS region
}

resource "aws_ecs_cluster" "my_cluster" {
  name = "ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_security_group" "security_group" {
  name        = "lb-security-group"
  description = "Security group for the load balancer"
  vpc_id      = aws_vpc.my_vpc.id

}

resource "aws_lb" "my_lb" {
  name               = "my-load-balancer"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.subnet.id
  security_groups    = aws_security_group.security_group.id
}
