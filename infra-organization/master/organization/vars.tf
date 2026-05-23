variable "terraform_init_user_name" {
  default = "terraform-init"
}

variable "administrator_default_arn" {
  default = "arn:aws:iam::aws:policy/AdministratorAccess"
}

variable "billing_default_arn" {
  default = "arn:aws:iam::aws:policy/job-function/Billing"
}

variable "aws_default_region" {
  default = "us-east-1"
}

variable "org_name" {
  default = "put info here!"
}

variable "terraform_state_bucket" {
  default = "put info here!"
}
variable "terraform_state_dynamodb_table" {
  default = "put info here!"
}

variable "security_acct_email" {
  default = "security@aaa.com"
}

variable "prod_acct_email" {
  default = "prod@aaa.com"
}

variable "stage_acct_email" {
  default = "stage@aaa.com"
}

variable "dev_acct_email" {
  default = "dev@aaa.com"
}

variable "shared_acct_email" {
  default = "shared@aaa.com"
}

