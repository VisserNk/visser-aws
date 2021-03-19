provider "aws" {
  region = "eu-west-1"
  profile = "terraform"
}

provider "aws" {
  region = "eu-south-1"
  alias = "italy"
  profile = "terraform"
}

resource "aws_vpc" "vpc1" {
  cidr_block = "10.1.0.0/16"
  
}

resource "aws_vpc" "vpc2" {
  cidr_block = "10.2.0.0/16"
  provider = aws.italy
}

resource "aws_internet_gateway" "gw1" {
  vpc_id = aws_vpc.vpc1.id
  
}

# resource "aws_internet_gateway" "gw2" {
#   vpc_id = aws_vpc.vpc2.id
# }

resource "aws_security_group" "group1" {
  vpc_id      = aws_vpc.vpc1.id
  
}

resource "aws_vpc_peering_connection" "peer1" {
  peer_vpc_id   = aws_vpc.vpc1.id
  vpc_id        = aws_vpc.vpc2.id
  peer_region   = "eu-west-1"
  auto_accept = false
  provider = aws.italy
}

resource "aws_vpc_peering_connection_accepter" "peer2" {
  vpc_peering_connection_id = aws_vpc_peering_connection.peer1.id
  auto_accept               = true
}

# resource "aws_vpc_peering_connection" "peer2" {
#   peer_vpc_id   = aws_vpc.vpc2.id
#   vpc_id        = aws_vpc.vpc1.id
# }

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

resource "aws_security_group" "group2" {
  vpc_id      = aws_vpc.vpc2.id
  provider = aws.italy
}

resource "aws_security_group_rule" "ssh2" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.group2.id
  provider = aws.italy
}

resource "aws_security_group_rule" "out2" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.group2.id
  provider = aws.italy
}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = true
  depends_on = [aws_internet_gateway.gw1]
  
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.vpc2.id
  cidr_block = "10.2.1.0/24"
  availability_zone = "eu-south-1a"
  provider = aws.italy
  #map_public_ip_on_launch = true
  #depends_on = [aws_internet_gateway.gw2]
}

resource "aws_route_table" "r1" {
  vpc_id = aws_vpc.vpc1.id
  

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw1.id
  }

  route {
    cidr_block = "10.2.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.peer1.id
  }
}

resource "aws_route_table" "r2" {
  vpc_id = aws_vpc.vpc2.id
  provider = aws.italy

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.gw2.id
#   }

  route {
    cidr_block = "10.1.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.peer1.id
  }
}

resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.r1.id
  
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.r2.id
  provider = aws.italy
}


resource "aws_network_interface" "iface1" {
  subnet_id   = aws_subnet.subnet1.id
  private_ips = ["10.1.1.10"]
  security_groups = [ aws_security_group.group1.id ]
  

  tags = {
    Name = "iface_sub1_inst1"
  }
}

resource "aws_network_interface" "iface2" {
  subnet_id   = aws_subnet.subnet2.id
  private_ips = ["10.2.1.10"]
  security_groups = [ aws_security_group.group2.id ]
  provider = aws.italy

  tags = {
    Name = "iface_sub2_inst2"
  }
}

resource "aws_key_pair" "visser" {
  key_name   = "visser-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHM3lDHm/C0KhlmES3lWOzna79RNNQuH2I+cWJ/AsiJXXprnmEta6/2vvvVwZGuBy3q4qTDUmETinSKmVEQjdmacGL3WistLJmmrjn7ZsczBi8ScJFqb603eseGlnGnQEByjwFmggEcLKGfxh/tFYm5Pl4y8uQdZpbkhUujmaYnpD6+SbgvO3TQaZ5WRyVeVm0z0aEhzevRBoM9jthWZLQalfkqgMEIF6Y6vGFstMvaXxzttmgsEdbwHL+9kcd5ibGuGnnUuv2BKTx3swh1nMZSrcewza4qa1LmVvmm7XUIBveMbvAlixSJLS9679mqehGdOUqJaFLfGxGfW+aIOKl visser@ESCANOR"
  
}

resource "aws_key_pair" "visser2" {
  key_name   = "visser-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHM3lDHm/C0KhlmES3lWOzna79RNNQuH2I+cWJ/AsiJXXprnmEta6/2vvvVwZGuBy3q4qTDUmETinSKmVEQjdmacGL3WistLJmmrjn7ZsczBi8ScJFqb603eseGlnGnQEByjwFmggEcLKGfxh/tFYm5Pl4y8uQdZpbkhUujmaYnpD6+SbgvO3TQaZ5WRyVeVm0z0aEhzevRBoM9jthWZLQalfkqgMEIF6Y6vGFstMvaXxzttmgsEdbwHL+9kcd5ibGuGnnUuv2BKTx3swh1nMZSrcewza4qa1LmVvmm7XUIBveMbvAlixSJLS9679mqehGdOUqJaFLfGxGfW+aIOKl visser@ESCANOR"
  provider = aws.italy
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

data "aws_ami" "ubuntu2" {
  most_recent = true
  provider = aws.italy

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
  ami           = data.aws_ami.ubuntu2.id
  instance_type = "t3.nano"
  //availability_zone = "eu-west-1a"
  //depends_on = [aws_internet_gateway.gw1]
  key_name = "visser-key"
  provider = aws.italy

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

output "inst1_ip_addr" {
  value = aws_instance.inst1.public_ip
}

# output "inst2_ip_addr" {
#   value = aws_instance.inst2.public_ip
# }

