
variable "subnetid" {
	type = string
}

variable "groupid" {
	type = string
}

variable "key" {
	type = string
}

variable "ec2ip" {
	type = string
}

variable "ec2type" {
	type = string
}

variable "tags" {
  type = map
  default = {}
}

variable "script" {
  type = string
}

variable "profileiam" {
  type = string
  default = ""
}

resource "aws_network_interface" "iface1" {
  subnet_id   = var.subnetid
  private_ips = [var.ec2ip]
  security_groups = [ var.groupid ]
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

resource "aws_instance" "inst1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2type
  availability_zone = "eu-west-1a"
  key_name = var.key
  user_data = file(var.script)
  iam_instance_profile = var.profileiam

  network_interface {
    network_interface_id = aws_network_interface.iface1.id
    device_index = 0
  }

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tags = var.tags

}

output "public_ip_addr" {
  value = aws_instance.inst1.public_ip
}

output "private_ip_addr" {
  value = var.ec2ip
}

output "id" {
  value = aws_instance.inst1.id
}

