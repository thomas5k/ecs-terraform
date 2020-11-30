
################################################################################
# VPC Info
################################################################################
output "vpc_arn" {
  description = "The ARN of the VPC used"
  value       = data.aws_vpc.selected.arn
}

output "vpc_id" {
  description = "The id of the VPC used"
  value       = data.aws_vpc.selected.id
}

################################################################################
# Subnet Info
################################################################################
output "private_subnet_ids" {
  description = "The private the subnets in the VPC"
  value       = data.aws_subnet_ids.private.ids
}

output "public_subnet_ids" {
  description = "The public the subnets in the VPC"
  value       = data.aws_subnet_ids.public.ids
}

################################################################################
# Bastion Host Info
################################################################################
output "ec2_bastion_host_id" {
  description = "ID of the Bastion Host for this VPC"
  value       = module.ec2_bastion_host.id
}

output "ec2_bastion_public_dns" {
  description = "List of public DNS names assigned to the instances"
  value       = module.ec2_bastion_host.public_dns
}

output "ec2_bastion_host_private_ip" {
  description = "Bastion Host Private IP"
  value       = module.ec2_bastion_host.private_ip
}

output "ec2_bastion_host_public_ip" {
  description = "Bastion Host Public IP"
  value       = module.ec2_bastion_host.public_ip
}

################################################################################
# Security Group Info
################################################################################
output "sg_bastion_host_sg_id" {
  description = "Bastion Security Group ID"
  value       = module.bastion_host_sg.this_security_group_id
}

output "sg_bastion_host_sg_name" {
  description = "Bastion Security Group Name"
  value       = module.bastion_host_sg.this_security_group_name
}