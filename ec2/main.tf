provider "aws" {
  region = "us-east-2"
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
# Look up subnets
################################################################################
data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.selected.id

  tags = {
    Tier = "private"
  }
}

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
# Look up latest Amazon Linux AMI
################################################################################
data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}

################################################################################
# Create SSH Keypair
################################################################################
resource "aws_key_pair" "master_key" {
  key_name   = "${data.aws_vpc.selected.tags["Name"]}-master-key"
  public_key = var.ec2_ssh_key_pub

  tags = {
    "Environment" = "dev"
  }
}

################################################################################
# Create a bastion host, place it in all public subnets
################################################################################
module "ec2_bastion_host" {
  depends_on     = [module.bastion_host_sg, aws_key_pair.master_key]
  source         = "github.com/terraform-aws-modules/terraform-aws-ec2-instance?ref=v2.15.0"
  instance_count = 1

  name                        = "${data.aws_vpc.selected.tags["Name"]}-bastion"
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_ids                  = data.aws_subnet_ids.public.ids
  vpc_security_group_ids      = [module.bastion_host_sg.this_security_group_id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.master_key.key_name

  tags = {
    "Environment" = "dev"
    "Tier"        = "public"
    "Type"        = "bastion"
  }
}

################################################################################
# Security Group For Bastion Host
################################################################################
module "bastion_host_sg" {
  source = "github.com/terraform-aws-modules/terraform-aws-security-group/modules/ssh"

  name            = "ssh"
  use_name_prefix = false
  vpc_id          = data.aws_vpc.selected.id

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = {
    "Environment" = "dev"
    "Tier"        = "public"
    "Type"        = "bastion"
  }
}

################################################################################
# Security Group For App Servers
################################################################################
module "app_host_sg" {
  source = "github.com/terraform-aws-modules/terraform-aws-security-group/modules/ssh"

  name            = "app"
  use_name_prefix = false
  vpc_id          = data.aws_vpc.selected.id

  ingress_cidr_blocks = [for s in data.aws_subnet.public: s.cidr_block]

  tags = {
    "Environment" = "dev"
    "Tier"        = "public"
    "Type"        = "bastion"
  }
}



################################################################################
# Create a regular linux host, place in private subnet
################################################################################
module "ec2_app_host" {
  depends_on     = [module.app_host_sg, aws_key_pair.master_key]
  source         = "github.com/terraform-aws-modules/terraform-aws-ec2-instance?ref=v2.15.0"
  instance_count = 1

  name                        = "${data.aws_vpc.selected.tags["Name"]}-app"
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_ids                  = data.aws_subnet_ids.private.ids
  vpc_security_group_ids      = [module.app_host_sg.this_security_group_id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.master_key.key_name

  tags = {
    "Environment" = "dev"
    "Tier"        = "private"
    "Type"        = "app"
  }
}