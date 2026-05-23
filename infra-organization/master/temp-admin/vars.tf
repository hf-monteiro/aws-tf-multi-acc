variable "keybase" {
  description = "Insira um perfil de base de chaves para criptografar a secret_key (Desencriptografar: terraform output secret_key | base64 --decode | keybase pgp decrypt)"
}

variable "security_acct_id" {}

variable "aws_default_region" {
  default = "us-east-1"
}

variable "terraform_state_bucket" {
  default = "put info here!"
}

variable "terraform_state_bucket_region" {
  default = "us-east-1"
}
