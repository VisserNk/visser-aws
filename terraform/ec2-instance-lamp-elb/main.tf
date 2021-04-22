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


resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = true
  depends_on = [aws_internet_gateway.gw1]
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-west-1b"
  map_public_ip_on_launch = true
  depends_on = [aws_internet_gateway.gw1]
}


resource "aws_network_interface" "iface1" {
  count = 3
  subnet_id   = aws_subnet.subnet1.id
  private_ips = ["10.0.1.${count.index + 10}"]
  security_groups = [ aws_security_group.group1.id ]

}

resource "aws_key_pair" "visser" {
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+nBPlZUcRr4yJSnT/i14QSFggXQWoIEPbSGd3+5MYyh+a6J1JkBodmmKc8bzD8NXrkXll/igZ1afyoruTG6pgJEJ3faM6j+9R+gznxQFdPDMkhvefQzQguB6Gagd+nbaoaM/7Z1kqg9KugLi8Ap9WzYA9tB4Az9zpQxyBvGA0tTtszsfJ5BtA0S5/+9cIT4PaUjV/B3WtfC8ePXZWP21IGn1CvbNtquuxcVoU8vdHm0OUj8YZAHthy0M/C+RskxMsaHtgtyAOTJcQiIhaLgKLrttn49YWBrHDyrL2CqYXNW+I17gECSclMkEq7x+alE7XtW5iuYI7ynPe27Fx9dnb visser@LAPTOP-LC3E8S5M"
}

resource "aws_lb" "alb1" {
  name               = "alb1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.group1.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  #enable_deletion_protection = true
}


resource "aws_lb_target_group" "albgroup1" {
  name     = "albgroup1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc1.id
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
  count = 3
  target_group_arn = aws_lb_target_group.albgroup1.arn
  target_id        = aws_instance.inst1[count.index].id
  port             = 80
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
  count = 3
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  availability_zone = "eu-west-1a"
  depends_on = [aws_internet_gateway.gw1]
  key_name = aws_key_pair.visser.key_name
  user_data = file("setup.sh")

  network_interface {
    network_interface_id = aws_network_interface.iface1[count.index].id
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
  value = aws_instance.inst1.*.public_ip
}

output "alb1_ip_addr" {
  value = aws_lb.alb1.dns_name
}
