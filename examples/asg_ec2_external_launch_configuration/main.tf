provider "aws" {
  region = "us-east-1"

  # Make it faster by skipping something
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}



#############################################################
# Data sources to get VPC Details
##############################################################


data "aws_vpc" "usbank_vpc" {
  filter {
    name = "tag:Name"
    values = [var.vpcname]
  }
}

##############################################################
# Data sources to get subnets
##############################################################

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.usbank_vpc.id
   filter {
    name   = "tag:10.60.3.0/24"
    values = ["az2-pri-subnet-3"] # insert value here
  }
}


data "aws_security_group" "this" {
  vpc_id = data.aws_vpc.usbank_vpc.id
  name   = var.elbsgname
   filter {
    name   = "tag:Name"
    values = ["usbank-appserv"]
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

#######################
# Launch configuration
# (сreating it outside of the module for example)
#######################
resource "aws_launch_configuration" "this" {
  name_prefix   = "my-launch-configuration-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  lifecycle {
    create_before_destroy = true
  }
}

module "example" {
  source = "../../"

  name = "example-with-ec2-external-lc"

  # Use of existing launch configuration (created outside of this module)
  launch_configuration = aws_launch_configuration.this.name

  create_lc = false

  recreate_asg_when_lc_changes = true

  # Auto scaling group
  asg_name                  = var.appsgname
  vpc_zone_identifier       = data.aws_subnet_ids.all.ids
  health_check_type         = "ELB"
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 0
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = "dev"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "megasecret"
      propagate_at_launch = true
    },
  ]

  tags_as_map = {
    extra_tag1 = "extra_value1"
    extra_tag2 = "extra_value2"
  }
}

