provider "aws" {
  region = "eu-west-1"
  profile = "terraform"
}

data "aws_vpc" "vpc1" {
  cidr_block = "10.0.0.0/16"
}

data "aws_subnet" "subnet1" {
  cidr_block = "10.0.0.0/24"
}

resource "aws_db_subnet_group" "subgrp1" {
  name       = "subgrp1"
  subnet_ids = [data.aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id     = data.aws_vpc.vpc1.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-1b"
  map_public_ip_on_launch = true
  //depends_on = [aws_internet_gateway.gw1]
}

data "aws_security_group" "group1" {
  name = "security_1"
}

resource "aws_db_instance" "rds1" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.subgrp1.name
  multi_az = false
  vpc_security_group_ids = [data.aws_security_group.group1.id]
}

output "rds1_ip" {
  value = aws_db_instance.rds1.address
}

output "rds1_endpoint" {
  value = aws_db_instance.rds1.endpoint
}