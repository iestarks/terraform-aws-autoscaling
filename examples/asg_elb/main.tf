provider "aws" {
  region = "us-east-1"
}


locals{
    subnet_ids_string = join(",", data.aws_subnet_ids.private.ids)
  subnet_ids_list = split(",", local.subnet_ids_string)

}

#############################################################
# Data sources to get VPC Details
##############################################################
data "aws_vpc" "usbank_vpc" {
  filter {
    name = "tag:Name"
    values = ["bankus_east-1-vpc"]
  }
}


##############################################################
# Data sources to get subnets
##############################################################

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.usbank_vpc.id
 tags = {
    Name = "bankus_east-1-vpc-public-*"
 }

  # tags = {
  # Name = "bankus_east-1-vpc-db-us-east-1a",
  # Name = "bankus_east-1-vpc-db-us-east-1c",  # insert value here

}

data "aws_subnet" "private" {
  vpc_id = data.aws_vpc.usbank_vpc.id
  count = length(data.aws_subnet_ids.private.ids)
  id    = local.subnet_ids_list[count.index]
}


data "aws_security_group" "this" {
  vpc_id = data.aws_vpc.usbank_vpc.id
  #  filter {
  #   name   = "tag:Name"
     #values = ["bankus_east-1-vpc-public-us-east-1a"] # insert value here
  tags = {
  Name = "usbank-appserv"
  # insert value here
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}

######
# Launch configuration and autoscaling group
######



module "example_asg" {
  source = "../../"

  name = "usbankasg-with-elb"

  # Launch configuration
  #
  # launch_configuration = "my-existing-launch-configuration" # Use the existing launch configuration
  # create_lc = false # disables creation of launch configuration
  lc_name = "usbank-lc"

  image_id        = data.aws_ami.amazon_linux.id
  instance_type   = "t2.micro"
  security_groups = [data.aws_security_group.this.id]
  #security_groups = var.appsgname
  load_balancers  = [module.elb.this_elb_id]
  recreate_asg_when_lc_changes = var.recreate_asg_when_lc_changes
  associate_public_ip_address  = true


  ebs_block_device = [
    {
      device_name           = "/dev/xvdz"
      volume_type           = "gp2"
      volume_size           = "50"
      delete_on_termination = true
    },
  ]

  root_block_device = [
    {
      volume_size = "50"
      volume_type = "gp2"
    },
  ]

  # Auto scaling group
  asg_name                  = "example-asg"
  #vpc_zone_identifier       = data.aws_subnet.private.*.id
  health_check_type         = "ELB"
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 0
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = "stage"
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "ansiblekey"
      propagate_at_launch = true
    },
  ]
}

######
# ELB
######

#
module "elb" {
  source = "terraform-aws-modules/elb/aws"

  name = var.elbname

  subnets         = data.aws_subnet.private.*.id
  security_groups = data.aws_security_group.this.*.id
  #security_groups = [var.appname]
  internal        = false

  listener = [
    {
      instance_port     = "80"
      instance_protocol = "HTTP"
      lb_port           = "80"
      lb_protocol       = "HTTP"
    },
  ]

  health_check = {
    target              = "HTTP:80/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}
