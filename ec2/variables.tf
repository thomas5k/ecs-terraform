variable "vpc_name" {
  description = "Name of the VPC to use"
  type        = string
}
variable "ec2_ssh_key_pub" {
	description = "Public key as it would appear in in authorized_keys"
	type = string
	default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCQjGhX4xoDZCY5ReglDLARRDM2ZBH8sUDV20o0rndT4mj9UwJdODwN6q4KIcryz0rsr9R9rfZnbDnTga7XL1vnnVG97N1/6rfmIJ5Sp692kVAOwZW52ddFztRiMeVyMUvIw5RTNuKgpK3Q+XblmWe1Nsn5CvI7GFWSFFml4rhL4+5o8ZJfu5LXF0sp3LnOUft710Ns/G0H/wUgXcQRJPUkBIIhi7AmHdHoZZKM/Y4Z+tGLFnaxZ10vGHNih97ct9ANN1tdcmvSP0WIznbeUK25pCxJigiYm2soWVWL2eZEJBMnzwYF5bVLvMTtDNF9mO++0xJTlC15eSwpGB1eG/Ef"
}