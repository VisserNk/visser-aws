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

provider "aws" {
  region = "eu-west-1"
  profile = "terraform"
}

resource "aws_key_pair" "visser" {
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHM3lDHm/C0KhlmES3lWOzna79RNNQuH2I+cWJ/AsiJXXprnmEta6/2vvvVwZGuBy3q4qTDUmETinSKmVEQjdmacGL3WistLJmmrjn7ZsczBi8ScJFqb603eseGlnGnQEByjwFmggEcLKGfxh/tFYm5Pl4y8uQdZpbkhUujmaYnpD6+SbgvO3TQaZ5WRyVeVm0z0aEhzevRBoM9jthWZLQalfkqgMEIF6Y6vGFstMvaXxzttmgsEdbwHL+9kcd5ibGuGnnUuv2BKTx3swh1nMZSrcewza4qa1LmVvmm7XUIBveMbvAlixSJLS9679mqehGdOUqJaFLfGxGfW+aIOKl visser@ESCANOR"
}

module "network" {
	source = "../modules/network"
}

module "security" {
	source = "../modules/security"

	vpcid = module.network.vpcid
}

module "ec2instance1" {
	source = "../modules/ec2instance"

	subnetid = module.network.subnetid
	groupid = module.security.groupid
	key = aws_key_pair.visser.key_name
	ec2ip = "10.0.1.10"
	ec2type = "t2.nano"
}

module "ec2instance2" {
	source = "../modules/ec2instance"

	subnetid = module.network.subnetid
	groupid = module.security.groupid
	key = aws_key_pair.visser.key_name
	ec2ip = "10.0.1.20"
	ec2type = "t2.nano"
}

module "ec2instanceN" {
	count = 8
	source = "../modules/ec2instance"

	subnetid = module.network.subnetid
	groupid = module.security.groupid
	key = aws_key_pair.visser.key_name
	ec2ip = "10.0.1.${count.index+30}"
	ec2type = "t2.nano"
}

output "ip_1" {
	value = module.ec2instance1.public_ip_addr
}
output "ip_2" {
	value = module.ec2instance2.public_ip_addr
}

output "ip_N" {
	value = module.ec2instanceN.*.public_ip_addr
}