# provider "aws" {
#   region = "eu-west-1"
#   profile = "terraform"
# }

variable "vpcid" {
  type = string
}

resource "aws_security_group" "group1" {
  vpc_id      = var.vpcid
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

output "groupid" {
  value = aws_security_group.group1.id
}

