locals {
  name        = "${var.vpc_name}-ecs-asg"
  environment = var.vpc_environment

  # This is the convention we use to know what belongs to each other
  # TODO this probably should change
  ec2_resources_name = "${local.name}-${local.environment}"

  tags = concat([
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
    }
  ], var.additional_tags)

  # Create ecs.config file so that instances register with the cluster
  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${var.ecs_cluster_name} >> /etc/ecs/ecs.config
EOF
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
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.17.0"

  name        = "${data.aws_vpc.selected.tags["Name"]}-ecs-asg-sg"
  description = "Public to Private Subnet Traffic"
  vpc_id      = data.aws_vpc.selected.id

  ingress_cidr_blocks = var.public_subnets
  # Rules are in https://github.com/terraform-aws-modules/terraform-aws-security-group/blob/master/rules.tf
  ingress_rules = ["http-80-tcp", "all-icmp", "ssh-tcp"]

  # Ephemeral port ranges are 49153–65535 and 32768–61000
  ingress_with_cidr_blocks = [
    {
      from_port = 32768
      to_port = 61000
      protocol = "tcp"
      description = "Ephemeral Container Ports"
      # TODO calculate these dynamically by checking the public subnets
      cidr_blocks = data.aws_vpc.selected.cidr_block
    },
    {
      from_port = 49153
      to_port = 65535
      protocol = "tcp"
      description = "Ephemeral Container Ports"
      # TODO calculate these dynamically by checking the public subnets
      cidr_blocks = data.aws_vpc.selected.cidr_block
    }
  ]

  # Instances need either outbound internet access OR access to VPC PrivateLink endpoints
  # for ECS, SSM, and other AS services as-needed.
  egress_rules = ["all-all"]

  tags = {
    "Environment" = var.vpc_environment
    "Tier"        = "private"
    "Type"        = "app"
  }
}


################################################################################
# Create Instance Policy Role
################################################################################
# See https://docs.aws.amazon.com/autoscaling/ec2/userguide/us-iam-role.html for
# why this is necessary when using a launch configuration
module "ecs_instance_profile" {
  source      = "terraform-aws-modules/ecs/aws//modules/ecs-instance-profile"
  version     = "2.5.0"
  name        = "my-instance-profile"
  include_ssm = true
  tags = {
    Environment = var.vpc_environment
  }
}

data "aws_subnet_ids" "private_subnets" {
  vpc_id = data.aws_vpc.selected.id
  filter {
    name = "cidr-block"
    values = var.private_subnets
  }
}

################################################################################
# Create the Auto Scaling Group
################################################################################
module "asg" {
  source     = "terraform-aws-modules/autoscaling/aws"
  version    = "~> 3.0"
  depends_on = [module.ecs_instance_profile]

  name = local.ec2_resources_name

  # Launch configuration
  lc_name              = local.ec2_resources_name
  image_id             = data.aws_ami.amazon_linux_ecs.id
  instance_type        = "t2.micro"
  security_groups      = [module.ecs_asg_host_sg.this_security_group_id]
  iam_instance_profile = module.ecs_instance_profile.this_iam_instance_profile_id
  key_name             = aws_key_pair.ecs_key.key_name
  user_data_base64     = base64encode(local.user_data)

  # Auto scaling group
  asg_name                  = local.ec2_resources_name
  vpc_zone_identifier       = data.aws_subnet_ids.private_subnets.ids
  health_check_type         = "EC2"
  min_size                  = 0
  max_size                  = 2
  desired_capacity          = 0
  wait_for_capacity_timeout = 0

  tags = local.tags
}
