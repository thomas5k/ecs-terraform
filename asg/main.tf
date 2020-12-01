locals {
  name        = "${var.vpc_name}-ecs-asg"
  environment = var.vpc_environment

  # This is the convention we use to know what belongs to each other
  ec2_resources_name = "${local.name}-${local.environment}"
}

provider "aws" {
  region = var.aws_region
}


################################################################################
# Lookup VPC
################################################################################
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

################################################################################
# Fetch the latest Amazon Linux ECS Optimized ami-id
################################################################################
data "aws_ami" "amazon_linux_ecs" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

################################################################################
# Look up public subnets
################################################################################
data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.selected.id

  tags = {
    Tier = "public"
  }
}

# Public Subnet info, using ids from data.aws_subnet_ids above
data "aws_subnet" "public" {
  for_each = data.aws_subnet_ids.public.ids
  id       = each.value
}

################################################################################
# Look up private subnets
################################################################################
data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.selected.id

  tags = {
    Tier = "private"
  }
}

################################################################################
# Create SSH Keypair
################################################################################
resource "aws_key_pair" "ecs_key" {
  key_name   = "${data.aws_vpc.selected.tags["Name"]}-ecs-key"
  public_key = var.ec2_ssh_key_pub

  tags = {
    "Environment" = var.vpc_environment
  }
}

################################################################################
# Create Security Group for ECS ASG Hosts
################################################################################
module "ecs_asg_host_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "${data.aws_vpc.selected.tags["Name"]}-ecs-asg-sg"
  description = "Allow SSH and HTTP traffic from public subnet CIDR blocks."
  vpc_id      = data.aws_vpc.selected.id

  ingress_cidr_blocks = [for s in data.aws_subnet.public : s.cidr_block]
  # Rules are in https://github.com/terraform-aws-modules/terraform-aws-security-group/blob/master/rules.tf
  ingress_rules = ["http-80-tcp", "all-icmp", "ssh-tcp"]
  egress_rules  = ["all-all"]

  tags = {
    "Environment" = var.vpc_environment
    "Tier"        = "private"
    "Type"        = "app"
  }
}

################################################################################
# Look up IAM Policy for ECS and apply to EC2
################################################################################
module "ec2_profile" {
  # TODO is this where this belongs?
  source = "github.com/terraform-aws-modules/terraform-aws-ecs/modules/ecs-instance-profile"

  name = local.name

  tags = {
    Environment = local.environment
  }
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  name = local.ec2_resources_name

  # Launch configuration
  lc_name = local.ec2_resources_name
  image_id             = data.aws_ami.amazon_linux_ecs.id
  instance_type        = "t2.micro"
  security_groups      = [module.ecs_asg_host_sg.this_security_group_id]
  iam_instance_profile = module.ec2_profile.this_iam_instance_profile_id
  key_name             = aws_key_pair.ecs_key.key_name

  # Auto scaling group
  asg_name                  = local.ec2_resources_name
  vpc_zone_identifier       = data.aws_subnet_ids.private.ids
  health_check_type         = "EC2"
  min_size                  = 0
  max_size                  = 2
  desired_capacity          = 1
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = local.environment
      propagate_at_launch = true
    },
    {
      key                 = "Cluster"
      value               = local.name
      propagate_at_launch = true
    },
    {
      key                 = "Tier"
      value               = "private"
      propagate_at_launch = true
    },
  ]
}
