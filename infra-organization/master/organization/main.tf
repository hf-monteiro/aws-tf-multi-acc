terraform {
  backend "s3" {}
}

data "aws_caller_identity" "current" {}

resource "aws_organizations_organization" "org" {
  feature_set = "ALL"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "security" {
  name       = "Security Account"
  email      = var.security_acct_email
  depends_on = [aws_organizations_organization.org]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "prod" {
  name       = "Production Account"
  email      = var.prod_acct_email
  depends_on = [aws_organizations_organization.org]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "stage" {
  name       = "Stage Account"
  email      = var.stage_acct_email
  depends_on = [aws_organizations_organization.org]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "dev" {
  name       = "Dev Account"
  email      = var.dev_acct_email
  depends_on = [aws_organizations_organization.org]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "shared" {
  name       = "Shared Account"
  email      = var.shared_acct_email
  depends_on = [aws_organizations_organization.org]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_account_alias" "alias" {
  account_alias = "${var.org_name}-master"
}

provider "aws" {
  alias = "assume_security"

  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.security.id}:role/OrganizationAccountAccessRole"
  }

  region = var.aws_default_region
}

provider "aws" {
  alias = "assume_prod"

  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.prod.id}:role/OrganizationAccountAccessRole"
  }

  region = var.aws_default_region
}

provider "aws" {
  alias = "assume_stage"

  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.stage.id}:role/OrganizationAccountAccessRole"
  }

  region = var.aws_default_region
}

provider "aws" {
  alias = "assume_dev"

  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.dev.id}:role/OrganizationAccountAccessRole"
  }

  region = var.aws_default_region
}

provider "aws" {
  alias = "assume_shared"

  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.shared.id}:role/OrganizationAccountAccessRole"
  }

  region = var.aws_default_region
}


data "aws_iam_policy_document" "terragrunt_admin" {
  statement {
    sid = "AllowS3ActionsOnTerraformBucket"

    actions = [
      "s3:CreateBucket",
      "s3:ListBucket",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning",
      "s3:GetBucketTagging",
      "s3:PutBucketTagging",
      "s3:GetEncryptionConfiguration",
      "s3:PutEncryptionConfiguration",
    ]

    resources = [
      "arn:aws:s3:::${var.terraform_state_bucket}",
    ]
  }

  statement {
    sid = "AllowGetAndPutS3ActionsOnTerraformBucketPath"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${var.terraform_state_bucket}/*",
    ]
  }

  statement {
    sid = "AllowCreateAndUpdateDynamoDBActionsOnTerraformLockTable"

    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
      "dynamodb:CreateTable",
    ]

    resources = [
      "arn:aws:dynamodb:*:*:table/${var.terraform_state_dynamodb_table}",
    ]
  }

  statement {
    sid = "AllowTagAndUntagDynamoDBActions"

    actions = [
      "dynamodb:TagResource",
      "dynamodb:UntagResource",

    ]

    resources = [
      "*",


    ]
  }
}


resource "aws_iam_policy" "terragrunt_admin" {
  name        = "TerragruntAdminAccess"
  policy      = data.aws_iam_policy_document.terragrunt_admin.json
  description = "Grants permissions needed by terragrunt to manage Terraform remote state"
  provider    = aws.assume_security
}

data "aws_iam_policy_document" "terragrunt_reader" {
  statement {
    sid = "AllowListS3ActionsOnTerraformBucket"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${var.terraform_state_bucket}",
    ]
  }

  statement {
    sid = "AllowGetS3ActionsOnTerraformBucketPath"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${var.terraform_state_bucket}/*",
    ]
  }
}

resource "aws_iam_policy" "terragrunt_reader" {
  name        = "TerragruntReadAccess"
  policy      = data.aws_iam_policy_document.terragrunt_reader.json
  description = "Grants permissions to read Terraform remote state"
  provider    = aws.assume_security
}

data "aws_iam_policy_document" "crossaccount_assume_from_security" {
  statement {
    sid     = "AssumeFromSecurity"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${aws_organizations_account.security.id}:root"]
    }
  }
}

data "aws_iam_policy_document" "crossaccount_assume_from_security_and_master" {
  statement {
    sid     = "AssumeFromSecurityAndMaster"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${aws_organizations_account.security.id}:root",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
  }
}

module "cross_account_role_master_billing" {
  source                  = "../../infrastructure-modules/cross-account-role"
  assume_role_policy_json = data.aws_iam_policy_document.crossaccount_assume_from_security.json
  role                    = "Billing"
  role_policy_arn         = var.billing_default_arn
}

module "cross_account_role_security" {
  source = "../../infrastructure-modules/cross-account-role"

  providers = {
    aws = aws.assume_security
  }

  assume_role_policy_json = data.aws_iam_policy_document.crossaccount_assume_from_security.json
  role                    = "Administrator"
  role_policy_arn         = var.administrator_default_arn
}

module "cross_account_role_prod" {
  source = "../../infrastructure-modules/cross-account-role"

  providers = {
    aws = aws.assume_prod
  }

  assume_role_policy_json = data.aws_iam_policy_document.crossaccount_assume_from_security.json
  role                    = "Administrator"
  role_policy_arn         = var.administrator_default_arn
}

module "cross_account_role_stage" {
  source = "../../infrastructure-modules/cross-account-role"

  providers = {
    aws = aws.assume_stage
  }

  assume_role_policy_json = data.aws_iam_policy_document.crossaccount_assume_from_security.json
  role                    = "Administrator"
  role_policy_arn         = var.administrator_default_arn
}

module "cross_account_role_dev" {
  source = "../../infrastructure-modules/cross-account-role"

  providers = {
    aws = aws.assume_dev
  }

  assume_role_policy_json = data.aws_iam_policy_document.crossaccount_assume_from_security.json
  role                    = "Administrator"
  role_policy_arn         = var.administrator_default_arn
}

module "cross_account_role_shared" {
  source = "../../infrastructure-modules/cross-account-role"

  providers = {
    aws = aws.assume_shared
  }

  assume_role_policy_json = data.aws_iam_policy_document.crossaccount_assume_from_security.json
  role                    = "Administrator"
  role_policy_arn         = var.administrator_default_arn
}


module "cross_account_role_terragrunt_admin" {
  source = "../../infrastructure-modules/cross-account-role"

  providers = {
    aws = aws.assume_security
  }

  assume_role_policy_json = data.aws_iam_policy_document.crossaccount_assume_from_security_and_master.json
  role                    = "TerragruntAdministrator"
  role_policy_arn         = aws_iam_policy.terragrunt_admin.arn
}

module "cross_account_role_terragrunt_reader" {
  source = "../../infrastructure-modules/cross-account-role"

  providers = {
    aws = aws.assume_security
  }

  assume_role_policy_json = data.aws_iam_policy_document.crossaccount_assume_from_security_and_master.json
  role                    = "TerragruntReader"
  role_policy_arn         = aws_iam_policy.terragrunt_reader.arn
}

module "assume_role_policy_master_billing" {
  source = "../../infrastructure-modules/assume-role-policy"

  providers = {
    aws = aws.assume_security
  }

  account_name = "master"
  account_id   = data.aws_caller_identity.current.account_id
  role         = module.cross_account_role_master_billing.role_name
}

module "assume_role_policy_security_admin" {
  source = "../../infrastructure-modules/assume-role-policy"

  providers = {
    aws = aws.assume_security
  }

  account_name = "security"
  account_id   = aws_organizations_account.security.id
  role         = module.cross_account_role_security.role_name
}

module "assume_role_policy_prod_admin" {
  source = "../../infrastructure-modules/assume-role-policy"

  providers = {
    aws = aws.assume_security
  }

  account_name = "prod"
  account_id   = aws_organizations_account.prod.id
  role         = module.cross_account_role_prod.role_name
}

module "assume_role_policy_stage_admin" {
  source = "../../infrastructure-modules/assume-role-policy"

  providers = {
    aws = aws.assume_security
  }

  account_name = "stage"
  account_id   = aws_organizations_account.stage.id
  role         = module.cross_account_role_stage.role_name
}

module "assume_role_policy_dev_admin" {
  source = "../../infrastructure-modules/assume-role-policy"

  providers = {
    aws = aws.assume_security
  }

  account_name = "dev"
  account_id   = aws_organizations_account.dev.id
  role         = module.cross_account_role_dev.role_name
}

module "assume_role_policy_shared_admin" {
  source = "../../infrastructure-modules/assume-role-policy"

  providers = {
    aws = aws.assume_security
  }

  account_name = "shared"
  account_id   = aws_organizations_account.shared.id
  role         = module.cross_account_role_shared.role_name
}

module "assume_role_policy_terragrunt_admin" {
  source = "../../infrastructure-modules/assume-role-policy"

  providers = {
    aws = aws.assume_security
  }

  account_name = "security"
  account_id   = aws_organizations_account.security.id
  role         = module.cross_account_role_terragrunt_admin.role_name
}

module "assume_role_policy_terragrunt_reader" {
  source = "../../infrastructure-modules/assume-role-policy"

  providers = {
    aws = aws.assume_security
  }

  account_name = "security"
  account_id   = aws_organizations_account.security.id
  role         = module.cross_account_role_terragrunt_reader.role_name
}

module "assume_role_policy_terragrunt_admin_from_master" {
  source       = "../../infrastructure-modules/assume-role-policy"
  account_name = "security"
  account_id   = aws_organizations_account.security.id
  role         = module.cross_account_role_terragrunt_admin.role_name
}

resource "aws_iam_user_policy_attachment" "assume_role_policy_terragrunt_admin_from_master" {
  user       = var.terraform_init_user_name
  policy_arn = module.assume_role_policy_terragrunt_admin_from_master.policy_arn
}

module "assume_role_policy_terragrunt_reader_from_master" {
  source       = "../../infrastructure-modules/assume-role-policy"
  account_name = "security"
  account_id   = aws_organizations_account.security.id
  role         = module.cross_account_role_terragrunt_reader.role_name
}

resource "aws_iam_user_policy_attachment" "assume_role_policy_terragrunt_reader_from_master" {
  user       = var.terraform_init_user_name
  policy_arn = module.assume_role_policy_terragrunt_reader_from_master.policy_arn
}

