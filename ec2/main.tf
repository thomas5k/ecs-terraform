provider "aws" {
  region = "us-east-2"
}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}



# resource "aws_subnet" "example" {
#   vpc_id            = data.aws_vpc.selected.id
#   availability_zone = "us-west-2a"
#   cidr_block        = cidrsubnet(data.aws_vpc.selected.cidr_block, 4, 1)
# }