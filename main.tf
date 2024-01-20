provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "bastion" {
  ami           = "ami-0005e0cfe09cc9050"
  instance_type = "t2.micro"
  key_name      = "vockey"
  tags = {
    Name = "BastionHost"
  }
}

resource "aws_security_group" "bastion" {
  name        = "BastionSG"
  description = "Host safety"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app" {
  ami           = "ami-0005e0cfe09cc9050"
  instance_type = "t2.micro"

  tags = {
    Name = "AppInstance"
  }
}

resource "aws_security_group" "app" {
  name        = "AppSG"
  description = "App safety"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
}

resource "aws_security_group" "db" {
  name        = "DbSG"
  description = "DB safety"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
}

resource "aws_autoscaling_group" "app" {
  desired_capacity      = 1
  max_size              = 1
  min_size              = 1
  health_check_type     = "EC2"
  launch_configuration  = aws_launch_configuration.app.id
}

resource "aws_launch_configuration" "app" {
  image_id        = "ami-0005e0cfe09cc9050"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.app.id]
}

resource "aws_lb" "app" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app.id]
  subnets            = ["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_target_group" "app" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-abcde012"
}
