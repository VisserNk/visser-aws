provider "aws" {
  region = "eu-west-1"
  profile = "terraform"
}

resource "aws_vpc" "vpc1" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gw1" {
  vpc_id = aws_vpc.vpc1.id
}


resource "aws_security_group" "group1" {
  vpc_id      = aws_vpc.vpc1.id
}

resource "aws_security_group" "group2" {
  vpc_id      = aws_vpc.vpc2.id
}

resource "aws_security_group_rule" "web" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.group1.id
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
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
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = true
  depends_on = [aws_internet_gateway.gw1]
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.vpc2.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-west-1a"
}

resource "aws_network_interface" "iface1" {
  subnet_id   = aws_subnet.subnet1.id
  private_ips = ["10.0.1.10"]
  security_groups = [ aws_security_group.group1.id ]

  tags = {
    Name = "iface_sub1_inst1"
  }
}

resource "aws_route_table" "r1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw1.id
  }
}

resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.r1.id
}

resource "aws_network_interface" "iface2" {
  subnet_id   = aws_subnet.subnet2.id
  private_ips = ["10.0.2.10"]

  tags = {
    Name = "iface_sub2_inst2"
  }
}

resource "aws_ebs_volume" "vol1" {
  availability_zone = "eu-west-1a"
  size  = 10
  type = "gp2"

  tags = {
    Name = "ebs_inst1"
  }
}

resource "aws_ebs_volume" "vol2" {
  availability_zone = "eu-west-1a"
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

resource "aws_key_pair" "visser" {
  key_name   = "visser-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHM3lDHm/C0KhlmES3lWOzna79RNNQuH2I+cWJ/AsiJXXprnmEta6/2vvvVwZGuBy3q4qTDUmETinSKmVEQjdmacGL3WistLJmmrjn7ZsczBi8ScJFqb603eseGlnGnQEByjwFmggEcLKGfxh/tFYm5Pl4y8uQdZpbkhUujmaYnpD6+SbgvO3TQaZ5WRyVeVm0z0aEhzevRBoM9jthWZLQalfkqgMEIF6Y6vGFstMvaXxzttmgsEdbwHL+9kcd5ibGuGnnUuv2BKTx3swh1nMZSrcewza4qa1LmVvmm7XUIBveMbvAlixSJLS9679mqehGdOUqJaFLfGxGfW+aIOKl visser@ESCANOR"
}

resource "aws_instance" "inst1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.nano"
  availability_zone = "eu-west-1a"
  depends_on = [aws_internet_gateway.gw1]
  key_name = "visser-key"

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
}

resource "aws_instance" "inst2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.nano"
  availability_zone = "eu-west-1a"
  key_name = "visser-key"

  network_interface {
    network_interface_id = aws_network_interface.iface2.id
    device_index = 0
  }

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }

  credit_specification {
    cpu_credits = "standard"
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

output "inst1_ip_addr" {
  value = aws_instance.inst1.public_ip
}
