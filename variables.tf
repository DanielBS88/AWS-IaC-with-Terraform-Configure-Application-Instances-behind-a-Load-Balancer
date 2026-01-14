variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "project_name" {
  description = "Project identifier used for resource naming and tagging"
  type        = string
}

variable "ami_id" {
  description = "Amazon Machine Image ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the launch template"
  type        = string
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair for EC2 instance access"
  type        = string
}

variable "vpc_name" {
  description = "Name of the existing VPC"
  type        = string
}

variable "public_subnet_cidr_a" {
  description = "CIDR block for public subnet in availability zone A"
  type        = string
}

variable "private_subnet_cidr_a" {
  description = "CIDR block for private subnet in availability zone A"
  type        = string
}

variable "public_subnet_cidr_b" {
  description = "CIDR block for public subnet in availability zone B"
  type        = string
}

variable "private_subnet_cidr_b" {
  description = "CIDR block for private subnet in availability zone B"
  type        = string
}

variable "ec2_sg_name" {
  description = "Name of the security group for SSH access to EC2 instances"
  type        = string
}

variable "http_sg_name" {
  description = "Name of the security group for HTTP access to EC2 instances"
  type        = string
}

variable "lb_sg_name" {
  description = "Name of the security group for the load balancer"
  type        = string
}

variable "instance_profile_name" {
  description = "Name of the IAM instance profile for EC2 instances"
  type        = string
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
}

variable "asg_min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
}

variable "asg_max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
}
