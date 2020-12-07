variable "aws_region" {
  description = "AWS Region to place resources (AZs are fixed here, so this must be us-east-2 for now)"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC to create"
  type        = string
}

variable "vpc_environment" {
  description = "What type of environment, i.e. 'dev', 'test', 'prod'"
  type        = string

  validation {
    condition     = var.vpc_environment == "dev" || var.vpc_environment == "test" || var.vpc_environment == "prod"
    error_message = "Must be one of 'dev', 'test', or 'prod'."
  }
}

variable "ec2_ssh_key_pub" {
  description = "Public key as it would appear in in authorized_keys"
  type        = string
}

variable "vpc_subnet_mapping" {
  description = "Network topology of CIDRS and subnets."
  type = map
  default = {
    "azs"             = ["us-east-2a", "us-east-2b"]
    "private_subnets" = ["10.0.1.0/24", "10.0.2.0/24"]
    "public_subnets"  = ["10.0.101.0/24", "10.0.102.0/24"]
  }
}

variable "vpc_cidr" {
  description = "CIDR for entire VPC."
  type = string
  default = "10.0.0.0/16"
}