provider "aws" {
  region = var.region
  alias  = "shared"

  assume_role {
    role_arn = "arn:aws:iam::${data.terraform_remote_state.organization.outputs.shared_acct_id}:role/Administrator"
  }
}

provider "aws" {
  region = var.region
  alias  = "prod"

  assume_role {
    role_arn = "arn:aws:iam::${data.terraform_remote_state.organization.outputs.prod_acct_id}:role/Administrator"
  }
}

provider "aws" {
  region = var.region
  alias  = "staging"

  assume_role {
    role_arn = "arn:aws:iam::${data.terraform_remote_state.organization.outputs.stage_acct_id}:role/Administrator"
  }
}

provider "aws" {
  region = var.region
  alias  = "dev"

  assume_role {
    role_arn = "arn:aws:iam::${data.terraform_remote_state.organization.outputs.dev_acct_id}:role/Administrator"
  }
}