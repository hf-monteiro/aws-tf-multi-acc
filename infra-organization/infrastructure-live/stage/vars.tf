variable "terraform_state_bucket" {
  default = "put info here!"
}

variable "terraform_state_bucket_region" {
  default = "put info here!"
}

variable "aws_default_region" {
  default = "put info here!"
}

variable "org_name" {
  default = "put info here!"
}

variable "developer_role_name" {
  default = "Developer"
}

variable "developer_default_arn" {
  default = "arn:aws:iam::aws:policy/PowerUserAccess"
}
/*
## VPC ##

variable "cidr_vpc" {
    default = "10.2.0.0/16"
}

variable "az" {
    default = "us-east-1c"
}

variable "cidr_sub" {
    default = "10.2.1.0/24"
}

variable "instance_tenancy" {
    default = "default"
}*/