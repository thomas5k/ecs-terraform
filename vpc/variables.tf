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
}

variable "azs" {
  description = "Network topology of CIDRS and subnets."
  type = list
}

variable "private_subnets" {
  description = "Network topology of CIDRS and subnets."
  type = list
}

variable "public_subnets" {
  description = "Network topology of CIDRS and subnets."
  type = list
}

variable "vpc_cidr" {
  description = "CIDR for entire VPC."
  type = string
}