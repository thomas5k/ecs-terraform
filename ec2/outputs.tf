output "vpc_arn" {
  description = "The ARN of the VPC used"
  value       = data.aws_vpc.selected.arn
}

output "vpc_id" {
  description = "The id of the VPC used"
  value       = data.aws_vpc.selected.id
}