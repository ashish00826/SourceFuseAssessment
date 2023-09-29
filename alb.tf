//Set the default route for the ALB that serves the default route of the nginx image

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "my_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_security_group" "alb_sg" {
  name_prefix = "alb-sg-"
}

resource "aws_security_group_rule" "alb_http_ingress" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.my_subnet.id
  security_groups    = aws_security_group.alb_sg.id

  enable_deletion_protection = false
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      content      = "Hello from Nginx!"
    }
  }
}

resource "aws_lb_target_group" "my_target_group" {
  name        = "my-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.my_vpc.id
}

resource "aws_lb_target_group_attachment" "my_target_attachment" {
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id        = aws_instance.my_instance.id
}

resource "aws_instance" "my_instance" {
  ami           = "ami-03a6eaae9938c858c"
  instance_type = "t2.micro"

  subnet_id = aws_subnet.my_subnet.id

  tags = {
    Name = "my-nginx-instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install nginx1 -y
              systemctl start nginx
              systemctl enable nginx
              EOF
}

resource "aws_security_group_rule" "nginx_ingress" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  security_group_id = aws_security_group.nginx_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group" "nginx_sg" {
  name_prefix = "nginx-sg-"
}

output "alb_dns_name" {
  value = aws_lb.my_alb.dns_name
}
