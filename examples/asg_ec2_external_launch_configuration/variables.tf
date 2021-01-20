variable "elbname" {
  description = "ELB Security Group Name"
  type        = string
  default = "http-80-elb"
}


variable "elbsgname" {
  description = "ELB Security Group Name"
  type        = string
  default = "http-80-sg"
}


variable "appsgname" {
  description = "ELB Security Group Name"
  type        = string
  default = "usbank-appserv"
}

variable "vpcname" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = "bankus_east-1-vpc"
}
