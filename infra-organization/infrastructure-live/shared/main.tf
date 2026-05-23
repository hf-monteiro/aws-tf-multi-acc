terraform {
  backend "s3" {}
}

data "aws_caller_identity" "current" {
  provider = aws.noassume
}

data "terraform_remote_state" "organization" {
  backend = "s3"

  config = {
    bucket   = var.terraform_state_bucket
    key      = "master/organization/terraform.tfstate"
    region   = var.terraform_state_bucket_region
    role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TerragruntReader"
  }
}

data "terraform_remote_state" "security" {
  backend = "s3"

  config = {
    bucket   = var.terraform_state_bucket
    key      = "infrastructure-live/security/terraform.tfstate"
    region   = var.terraform_state_bucket_region
    role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TerragruntReader"
  }
}

provider "aws" {
  alias  = "noassume"
  region = var.aws_default_region
}

provider "aws" {
  assume_role {
    role_arn = "arn:aws:iam::${data.terraform_remote_state.organization.outputs.shared_acct_id}:role/Administrator"
  }

  region = var.aws_default_region
}

resource "aws_iam_account_alias" "alias" {
  account_alias = "${var.org_name}-shared"
}

resource "aws_cloudtrail" "cloudtrail" {
  name                       = "cloudtrail-shared"
  s3_key_prefix              = "shared"
  s3_bucket_name             = data.terraform_remote_state.security.outputs.cloudtrail_bucket_id
  enable_log_file_validation = true
  is_multi_region_trail      = true
}

module "cross_account_role_developer" {
  source                  = "../../infrastructure-modules/cross-account-role"
  assume_role_policy_json = data.terraform_remote_state.organization.outputs.crossaccount_assume_from_security_policy_json
  role                    = var.developer_role_name
  role_policy_arn         = var.developer_default_arn
}

### TRANSIT GATEWAY ###

# Create the Transit Gateway, route table associations/propagations, and static TGW routes in the `network` account.
# Enable sharing the Transit Gateway with the Organization using Resource Access Manager (RAM).
# If you would like to share resources with your organization or organizational units,
# then you must use the AWS RAM console or CLI command to enable sharing with AWS Organizations.

module "transit_gateway" {
  source = "../../infrastructure-modules/transit_gateway"

  ram_resource_share_enabled = false

  create_transit_gateway                                         = true
  create_transit_gateway_route_table                             = true
  create_transit_gateway_vpc_attachment                          = false
  create_transit_gateway_route_table_association_and_propagation = false
}
