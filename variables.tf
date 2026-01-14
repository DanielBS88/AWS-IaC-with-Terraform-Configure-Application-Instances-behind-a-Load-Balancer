variable "vpc_name" {
  description = "Name tag of the pre-existing VPC"
  type        = string
}

variable "ec2_sg_name" {
  description = "Security Group name that allows SSH access to EC2 instances"
  type        = string
}

variable "http_sg_name" {
  description = "Security Group name that allows HTTP access to EC2 instances"
  type        = string
}

variable "alb_sg_name" {
  description = "Security Group name for the Application Load Balancer"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM Instance Profile name attached to EC2 instances"
  type        = string
}

variable "ssh_key_name" {
  description = "SSH key pair name used to access EC2 instances"
  type        = string
}

variable "ami_id" {
  description = "AMI ID used for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "launch_template_name" {
  description = "Name of the EC2 Launch Template"
  type        = string
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

variable "target_group_name" {
  description = "Name of the ALB target group"
  type        = string
}

variable "project_name" {
  description = "Project tag applied to all resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
}
