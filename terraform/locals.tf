# Names derived from var.project_name (edit knobs in tfvars, not here).
data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name_prefix = var.project_name
  azs         = slice(data.aws_availability_zones.available.names, 0, 2)

  name_vpc         = "${local.name_prefix}-vpc"
  name_igw         = "${local.name_prefix}-igw"
  name_public_rt   = "${local.name_prefix}-public-rt"
  name_alb_sg      = "${local.name_prefix}-alb-sg"
  name_app_sg      = "${local.name_prefix}-app-sg"
  name_data_sg     = "${local.name_prefix}-data-sg"
  name_ec2_role    = "${local.name_prefix}-ec2-role"
  name_ec2_profile = "${local.name_prefix}-ec2-profile"
  name_gha_role    = "${local.name_prefix}-github-actions"
  name_alb         = "${local.name_prefix}-alb"
  name_tg          = "${local.name_prefix}-app-tg"
  name_asg         = "${local.name_prefix}-app-asg"
  name_app         = "${local.name_prefix}-app"
  name_data        = "${local.name_prefix}-data"
  name_alarms      = "${local.name_prefix}-alarms"
  name_alarm_5xx   = "${local.name_prefix}-alb-5xx"
  name_alarm_uh    = "${local.name_prefix}-unhealthy-hosts"
  name_dashboard   = "${local.name_prefix}-phase02"

  ecr_repos = ["frontend", "backend", "agent"]

  github_repo_sub = "repo:${var.github_org}/${var.github_repo}"
}
