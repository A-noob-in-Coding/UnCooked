variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "uncooked"
}

variable "instance_type" {
  type    = string
  default = "m7i-flex.large"
}

variable "asg_min" {
  type    = number
  default = 2
}

variable "asg_desired" {
  type    = number
  default = 2
}

variable "asg_max" {
  type    = number
  default = 4
}

variable "github_org" {
  type    = string
  default = "m-ahmad-butt"
}

variable "github_repo" {
  type    = string
  default = "UnCooked"
}

variable "alarm_email" {
  type        = string
  default     = ""
  description = "SNS email for ALB alarms (empty = no subscription)"
}

variable "budget_email" {
  type        = string
  default     = ""
  description = "Email for AWS monthly budget alerts (empty = skip budget)"
}

variable "budget_limit_usd" {
  type        = number
  default     = 50
  description = "Monthly AWS budget limit in USD"
}
