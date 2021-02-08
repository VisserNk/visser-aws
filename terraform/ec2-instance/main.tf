provider "aws" {
  region = "eu-west-1"
}

resource "aws_vpc" "vpc1" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gw1" {
  vpc_id = aws_vpc.vpc1.id
}

resource "aws_security_group" "group1" {
  name        = "security group vpc1"
  vpc_id      = aws_vpc.vpc1.id
}

resource "aws_security_group_rule" "web" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.group1.id
}

resource "aws_security_group_rule" "out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.group1.id
}

resource "aws_vpc" "vpc2" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.vpc2.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_network_interface" "iface1" {
  subnet_id   = aws_subnet.subnet1.id
  private_ips = ["10.0.1.1"]

  tags = {
    Name = "iface_sub1_inst1"
  }
}

resource "aws_network_interface" "iface2" {
  subnet_id   = aws_subnet.subnet2.id
  private_ips = ["10.0.2.1"]

  tags = {
    Name = "iface_sub2_inst2"
  }
}

resource "aws_ebs_volume" "vol1" {
  availability_zone = "eu-west-1"
  size  = 10
  type = "gp2"

  tags = {
    Name = "ebs_inst1"
  }
}

resource "aws_ebs_volume" "vol2" {
  availability_zone = "eu-west-1"
  size  = 10
  type = "gp2"

  tags = {
    Name = "ebs_inst2"
  }
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
  ami           = "ubuntu"
  instance_type = "t2.micro"
  depends_on = [aws_internet_gateway.gw1]
  vpc_security_group_ids = [aws_security_group.group1.id]

  network_interface {
    network_interface_id = aws_network_interface.iface1.id
    device_index = 0
  }

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

}

resource "aws_instance" "inst2" {
  ami           = "ubuntu"
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.iface2.id
    device_index = 0
  }

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
}

resource "aws_volume_attachment" "vol1_inst1" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.vol1.id
  instance_id = aws_instance.inst1.id
}

resource "aws_volume_attachment" "vol2_inst2" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.vol2.id
  instance_id = aws_instance.inst2.id
}