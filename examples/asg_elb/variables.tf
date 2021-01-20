variable "elbname" {
  description = "ELB Security Group Name"
  type        = string
  default = "autoscaling-elb"
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


