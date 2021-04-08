# provider "aws" {
#   region = "eu-west-1"
#   profile = "terraform"
# }

resource "aws_vpc" "vpc1" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gw1" {
  vpc_id = aws_vpc.vpc1.id
}


resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = true
  depends_on = [aws_internet_gateway.gw1]
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


output "vpcid" {
  value = aws_vpc.vpc1.id
}

output "subnetid" {
  value = aws_subnet.subnet1.id
}
