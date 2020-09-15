terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

variable "env" {
  default = "bastion-host"
}
variable "amis" {
  type = map
  default = {
    "bastion-host" = "ami-06b263d6ceff0b3dd"
  }
}
resource "aws_key_pair" "bastion-host" {
  key_name   = var.env
  public_key = file("id_rsa.pub")
}
#Default VPC
resource "aws_default_vpc" "default" {}

#Port 22 for SSH and port 8080 for jenkins
resource "aws_security_group" "bastion-host-sg" {
  name        = "Allow SSH and Jenkins HTTP(S)"
  description = "Allow Jenkins/SSH inbound traffic"
  vpc_id      = aws_default_vpc.default.id
  ingress {
    description = "Allow SSH from 0.0.0.0"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    description = "Allow Jenkins HTTPS from 0.0.0.0"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.env
  }
}
resource "aws_iam_instance_profile" "kops_profile" {
  name = "kops_profile"
  role = aws_iam_role.kops.name
}
resource "aws_iam_role" "kops" {
  name = "kops"
  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
  EOF
}
resource "aws_iam_role_policy" "kops_policy" {
  name = "kops"
  role = aws_iam_role.kops.id
  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:*",
                "s3:*",
                "route53:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "autoscaling:*"
            ],
            "Resource": "*"
        }
    ]
  }
  EOF
}
resource "aws_instance" "bastion-host" {
  ami           = var.amis[var.env]
  instance_type = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids =  [aws_security_group.bastion-host-sg.id]
  key_name      = aws_key_pair.bastion-host.id
  iam_instance_profile   = aws_iam_instance_profile.kops_profile.name
  tags = {
   Name = var.env
  }
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("id_rsa.pub")
    host        = self.public_ip
  }
  provisioner "local-exec" {
    command = "echo ${aws_instance.bastion-host.public_ip} > public_ip.txt"
  }
  lifecycle {
    create_before_destroy = true
  }
  user_data = file("install_jenkins_kops.sh")
}
