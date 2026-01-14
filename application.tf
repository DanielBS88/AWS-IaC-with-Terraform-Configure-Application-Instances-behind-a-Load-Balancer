#################################
# Data Sources - Infra existente
#################################

data "aws_vpc" "this" {
  tags = {
    Name = var.vpc_name
  }
}

data "aws_security_group" "ec2_sg" {
  name   = var.ec2_sg_name
  vpc_id = data.aws_vpc.this.id
}

data "aws_security_group" "http_sg" {
  name   = var.http_sg_name
  vpc_id = data.aws_vpc.this.id
}

data "aws_security_group" "alb_sg" {
  name   = var.alb_sg_name
  vpc_id = data.aws_vpc.this.id
}

data "aws_iam_instance_profile" "this" {
  name = var.instance_profile_name
}

#################################
# Public Subnets (CIDR-based)
#################################

data "aws_subnet" "public_a" {
  vpc_id     = data.aws_vpc.this.id
  cidr_block = "10.0.1.0/24"
}

data "aws_subnet" "public_b" {
  vpc_id     = data.aws_vpc.this.id
  cidr_block = "10.0.3.0/24"
}

#################################
# Launch Template
#################################

resource "aws_launch_template" "this" {
  name          = var.launch_template_name
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name

  vpc_security_group_ids = [
    data.aws_security_group.ec2_sg.id,
    data.aws_security_group.http_sg.id
  ]

  iam_instance_profile {
    name = data.aws_iam_instance_profile.this.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {}))

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Terraform = "true"
      Project   = var.project_name
    }
  }
}

#################################
# Target Group
#################################

resource "aws_lb_target_group" "this" {
  name     = var.target_group_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.this.id

  health_check {
    path = "/"
  }

  tags = {
    Terraform = "true"
    Project   = var.project_name
  }
}

#################################
# Application Load Balancer
#################################

resource "aws_lb" "this" {
  name               = var.alb_name
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.alb_sg.id]

  subnets = [
    data.aws_subnet.public_a.id,
    data.aws_subnet.public_b.id
  ]

  tags = {
    Terraform = "true"
    Project   = var.project_name
  }
}

#################################
# Listener
#################################

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

#################################
# Auto Scaling Group
#################################

resource "aws_autoscaling_group" "this" {
  name             = var.asg_name
  desired_capacity = 2
  min_size         = 1
  max_size         = 2

  vpc_zone_identifier = [
    data.aws_subnet.public_a.id,
    data.aws_subnet.public_b.id
  ]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [
      load_balancers,
      target_group_arns
    ]
  }

  tag {
    key                 = "Terraform"
    value               = "true"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }
}

#################################
# ASG → Target Group Attachment
#################################

resource "aws_autoscaling_attachment" "this" {
  autoscaling_group_name = aws_autoscaling_group.this.name
  lb_target_group_arn    = aws_lb_target_group.this.arn
}

