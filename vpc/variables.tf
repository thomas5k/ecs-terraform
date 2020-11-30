variable "aws_region" {
  description = "AWS Region to place resources (AZs are fixed here, so this must be us-east-2 for now)"
  type        = string
  default     = "us-east-2"
}

variable "vpc_name" {
  description = "Name of the VPC to create"
  type        = string
  default     = "pg-sandbox"
}