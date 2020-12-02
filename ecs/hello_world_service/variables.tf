variable "vpc_environment" {
  description = "What type of environment, i.e. 'dev', 'test', 'prod'"
  type        = string
  default     = "dev"

  validation {
    condition     = var.vpc_environment == "dev" || var.vpc_environment == "test" || var.vpc_environment == "prod"
    error_message = "Must be one of 'dev', 'test', or 'prod'."
  }
}

variable "aws_region" {
  description = "AWS Region to place resources (AZs are fixed here, so this must be us-east-2 for now)"
  type        = string
  default     = "us-east-2"
}

variable "vpc_name" {
  description = "Name of the VPC to use"
  type        = string
  default     = "pg-sandbox"
}

variable "ecs_cluster_id" {
  description = "ECS cluster id for the service."
  type        = string
}

