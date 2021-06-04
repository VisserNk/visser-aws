provider "aws" {
  region = "eu-west-1"
  profile = "terraform"
}

# module "ec2instance" {
# 	source = "../modules/ec2instance"
# }

# module "ec2instance2" {
# 	source = "../modules/ec2instance"
# }

# output "inst1_ip_addr" {
#   value = module.ec2instance.inst1_ip_addr
# }

# output "inst1_ip_addr2" {
#   value = module.ec2instance2.inst1_ip_addr
# }

variable "fleet_size" {
	type = number
	default = 5
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

resource "aws_lb_target_group_attachment" "attach1" {
  count = var.fleet_size
  target_group_arn = aws_lb_target_group.albgroup1.arn
  target_id        = module.ec2instance1[count.index].id
  port             = 80
}

resource "aws_key_pair" "visser" {
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHM3lDHm/C0KhlmES3lWOzna79RNNQuH2I+cWJ/AsiJXXprnmEta6/2vvvVwZGuBy3q4qTDUmETinSKmVEQjdmacGL3WistLJmmrjn7ZsczBi8ScJFqb603eseGlnGnQEByjwFmggEcLKGfxh/tFYm5Pl4y8uQdZpbkhUujmaYnpD6+SbgvO3TQaZ5WRyVeVm0z0aEhzevRBoM9jthWZLQalfkqgMEIF6Y6vGFstMvaXxzttmgsEdbwHL+9kcd5ibGuGnnUuv2BKTx3swh1nMZSrcewza4qa1LmVvmm7XUIBveMbvAlixSJLS9679mqehGdOUqJaFLfGxGfW+aIOKl visser@ESCANOR"
}

module "network" {
	source = "../modules/network"
}

module "policyS3" {
	source = "../modules/policyS3"
}

module "security" {
	source = "../modules/security"

	vpcid = module.network.vpcid
}

module "ec2instance1" {
	count = var.fleet_size
	source = "../modules/ec2instance"
	subnetid = module.network.subnetid
	groupid = module.security.groupid
	key = aws_key_pair.visser.key_name
	ec2ip = "10.0.1.${count.index + 10}"
	ec2type = "t2.nano"
	tags = { Name = "Deploiami" }
	script = "setup.sh"
	profileiam = module.policyS3.ec2_profile
}


output "ipS" {
	value = module.ec2instance1.*.public_ip_addr
}

output "alb1_ip_addr" {
  value = aws_lb.alb1.dns_name
}

# https://docs.aws.amazon.com/codedeploy/latest/userguide/instances-ec2-configure.html