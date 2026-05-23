variable "cloudtrail_bucket_name" {
  default = "put info here!"
}

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

variable "administrator_default_arn" {
  default = "arn:aws:iam::aws:policy/AdministratorAccess"
}

variable "developer_role_name" {
  default = "Developer"
}
/*
## VPC ##

variable "cidr_vpc" {
    default = "10.3.0.0/16"
}

variable "az" {
    default = "us-east-1c"
}

variable "cidr_sub" {
    default = "10.3.1.0/24"
}

variable "instance_tenancy" {
    default = "default"
}*/