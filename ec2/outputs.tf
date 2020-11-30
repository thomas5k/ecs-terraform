output "vpc_arn" {
  description = "The ARN of the VPC used"
  value       = data.aws_vpc.selected.arn
}

output "vpc_id" {
  description = "The id of the VPC used"
  value       = data.aws_vpc.selected.id
}

output "private_subnet_ids" {
  description = "The private the subnets in the VPC"
  value       = data.aws_subnet_ids.private.ids
}

output "public_subnet_ids" {
  description = "The public the subnets in the VPC"
  value       = data.aws_subnet_ids.public.ids
}