provider "aws" {
  region = "us-east-1"
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

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.usbank_vpc.id
  #  filter {
  #   name   = "tag:Name"
     #values = ["bankus_east-1-vpc-public-us-east-1a"] # insert value here
  tags = {
  Name = "bankus_east-1-vpc-public-us-east-1a" # insert value here
  }
}



data "aws_security_group" "this" {
 vpc_id = data.aws_vpc.usbank_vpc.id
  #  filter {
  #   name   = "tag:Name"
     #values = ["bankus_east-1-vpc-public-us-east-1a"] # insert value here
  tags = {
  Name = "usbank-appserv" # insert value here
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

  name = "example-with-elb"

  # Launch configuration
  #
  # launch_configuration = "my-existing-launch-configuration" # Use the existing launch configuration
  # create_lc = false # disables creation of launch configuration
  lc_name = "example-lc"

  image_id        = data.aws_ami.amazon_linux.id
  instance_type   = "t2.micro"
  security_groups = [data.aws_security_group.this.id]
  #security_groups = var.appsgname
  load_balancers  = [module.elb.this_elb_id]

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
  vpc_zone_identifier       = data.aws_subnet_ids.public.ids
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
      value               = "autoscale"
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

  subnets         = data.aws_subnet_ids.public.ids
  #security_groups = [data.aws_security_group.this.*.id]
  security_groups = [var.appname]
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
