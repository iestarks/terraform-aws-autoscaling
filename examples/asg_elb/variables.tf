variable "elbname" {
  description = "ELB Security Group Name"
  type        = string
  default = "autoscaling-elb2"
}

variable "create_lc" {
  description = "Whether to create launch configuration"
  type        = bool
  default     = true
}


variable "appname" {
  description = "App Name"
  type        = string
  default = "usbank-appserv"
}

variable "appsgname" {
  description = "APP Security Group Name"
  type        = string
  default = "usbank-appserv"
}

variable "recreate_asg_when_lc_changes" {
  description = "Whether to recreate an autoscaling group when launch configuration changes"
  type        = bool
  default     = false
}
