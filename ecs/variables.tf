variable "vpc_environment" {
  description = "What type of environment, i.e. 'dev', 'test', 'prod'."
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name."
  type        = string
}

variable "aws_region" {
  description = "AWS Region to place resources (AZs are fixed here, so this must be us-east-2 for now)."
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC to use/"
  type        = string
}

variable "ec2_ssh_key_pub" {
  description = "Public key as it would appear in in authorized_keys."
  type        = string
}

variable "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group to use use for our cluster."
  type        = string
}
