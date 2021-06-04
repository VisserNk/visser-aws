provider "aws" {
  region = "eu-west-1"
  profile = "terraform"
}

module "policyS3" {
	source = "../modules/policyS3"
}

module "network" {
	source = "../modules/network"
}

module "security" {
	source = "../modules/security"
  vpcid = module.network.vpcid
}

resource "aws_key_pair" "visser" {
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHM3lDHm/C0KhlmES3lWOzna79RNNQuH2I+cWJ/AsiJXXprnmEta6/2vvvVwZGuBy3q4qTDUmETinSKmVEQjdmacGL3WistLJmmrjn7ZsczBi8ScJFqb603eseGlnGnQEByjwFmggEcLKGfxh/tFYm5Pl4y8uQdZpbkhUujmaYnpD6+SbgvO3TQaZ5WRyVeVm0z0aEhzevRBoM9jthWZLQalfkqgMEIF6Y6vGFstMvaXxzttmgsEdbwHL+9kcd5ibGuGnnUuv2BKTx3swh1nMZSrcewza4qa1LmVvmm7XUIBveMbvAlixSJLS9679mqehGdOUqJaFLfGxGfW+aIOKl visser@ESCANOR"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_launch_configuration" "launch" {
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name = aws_key_pair.visser.key_name
  user_data = file("setup.sh")
  iam_instance_profile = module.policyS3.ec2_profile
  security_groups = [module.security.groupid]
}

resource "aws_placement_group" "placement" {
  name = "placement1"
  strategy = "spread"
}

resource "aws_autoscaling_group" "autogroup" {
  max_size                  = 5
  min_size                  = 3
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true
  placement_group           = aws_placement_group.placement.id
  launch_configuration      = aws_launch_configuration.launch.name
  vpc_zone_identifier       = [module.network.subnetid, module.network.subnet2id]

}

resource "aws_lb" "alb1" {
  name               = "alb1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.security.groupid]
  subnets            = [module.network.subnetid, module.network.subnet2id]

  #enable_deletion_protection = true
}


resource "aws_lb_target_group" "albgroup1" {
  name     = "albgroup1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.network.vpcid
}


resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb1.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.albgroup1.arn
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.autogroup.id
  alb_target_group_arn   = aws_lb_target_group.albgroup1.arn
}

output "alb1_ip_addr" {
  value = aws_lb.alb1.dns_name
}


# Setup applicazione web
# pipeline su terraform 
# implementazione autoscaling con moduli
# load balancer - multihost (https virtualhost)
# modifiche live (chef puppets)