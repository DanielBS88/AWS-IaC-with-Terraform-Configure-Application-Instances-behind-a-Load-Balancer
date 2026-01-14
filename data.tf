# Data sources para buscar recursos pré-existentes na AWS

data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  filter {
    name   = "cidr-block"
    values = [var.public_subnet_cidr_a, var.public_subnet_cidr_b]
  }
}

data "aws_security_group" "ec2_sg" {
  filter {
    name   = "group-name"
    values = [var.ec2_sg_name]
  }

  vpc_id = data.aws_vpc.existing.id
}

data "aws_security_group" "http_sg" {
  filter {
    name   = "group-name"
    values = [var.http_sg_name]
  }

  vpc_id = data.aws_vpc.existing.id
}

data "aws_security_group" "lb_sg" {
  filter {
    name   = "group-name"
    values = [var.lb_sg_name]
  }

  vpc_id = data.aws_vpc.existing.id
}

data "aws_iam_instance_profile" "existing" {
  name = var.instance_profile_name
}
