# Launch Template - Define como as instâncias EC2 serão criadas
resource "aws_launch_template" "main" {
  name          = local.launch_template_name
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name

  # Configuração de rede
  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups = [
      data.aws_security_group.ec2_sg.id,
      data.aws_security_group.http_sg.id
    ]
  }

  # Profile IAM para permissões da instância
  iam_instance_profile {
    name = data.aws_iam_instance_profile.existing.name
  }

  # Configuração de metadados
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  # Script de inicialização
  user_data = base64encode(local.user_data)

  tags = merge(
    local.common_tags,
    {
      Name = local.launch_template_name
    }
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.common_tags,
      {
        Name = "${local.launch_template_name}-instance"
      }
    )
  }
}

# Target Group - Agrupa instâncias para o Load Balancer
resource "aws_lb_target_group" "main" {
  name     = local.target_group_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.existing.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.target_group_name
    }
  )
}

# Application Load Balancer - Distribui tráfego
resource "aws_lb" "main" {
  name               = local.lb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.lb_sg.id]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = false

  tags = merge(
    local.common_tags,
    {
      Name = local.lb_name
    }
  )
}

# Listener - Escuta requisições HTTP na porta 80
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = local.common_tags
}

# Auto Scaling Group - Gerencia instâncias automaticamente
resource "aws_autoscaling_group" "main" {
  name                = local.asg_name
  desired_capacity    = var.asg_desired_capacity
  max_size            = var.asg_max_size
  min_size            = var.asg_min_size
  vpc_zone_identifier = data.aws_subnets.public.ids

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  # Ignora mudanças em load_balancers e target_group_arns
  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }

  tag {
    key                 = "Name"
    value               = local.asg_name
    propagate_at_launch = true
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

# Attachment - Conecta ASG ao Target Group do Load Balancer
resource "aws_autoscaling_attachment" "main" {
  autoscaling_group_name = aws_autoscaling_group.main.id
  lb_target_group_arn    = aws_lb_target_group.main.arn
}
