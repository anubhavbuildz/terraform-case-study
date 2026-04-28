provider "aws" {
  region = "us-east-1"
}

############################
# VPC
############################

resource "aws_vpc" "main_vpc" {

  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

############################
# Internet Gateway
############################

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main-igw"
  }
}

############################
# Subnets
############################

resource "aws_subnet" "subnet1" {

  vpc_id = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-1"
  }
}

resource "aws_subnet" "subnet2" {

  vpc_id = aws_vpc.main_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-2"
  }
}

############################
# Route Table
############################

resource "aws_route_table" "public_rt" {

  vpc_id = aws_vpc.main_vpc.id

  route {

    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id

  }
}

resource "aws_route_table_association" "rt1" {

  subnet_id = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public_rt.id

}

resource "aws_route_table_association" "rt2" {

  subnet_id = aws_subnet.subnet2.id
  route_table_id = aws_route_table.public_rt.id

}

############################
# Security Group
############################

resource "aws_security_group" "web_sg" {

  name = "apache-security-group"

  vpc_id = aws_vpc.main_vpc.id

  ingress {

    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {

    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {

    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}

############################
# Ubuntu AMI
############################

data "aws_ami" "ubuntu" {

  most_recent = true

  filter {

    name = "name"
    values = [
      "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    ]

  }

  owners = ["099720109477"]

}

############################
# EC2 Instance 1
############################

resource "aws_instance" "server1" {

  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  subnet_id = aws_subnet.subnet1.id

  vpc_security_group_ids = [
    aws_security_group.web_sg.id
  ]

  user_data = file("install_apache.sh")

  tags = {
    Name = "Apache-Server-1"
  }
}

############################
# EC2 Instance 2
############################

resource "aws_instance" "server2" {

  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  subnet_id = aws_subnet.subnet2.id

  vpc_security_group_ids = [
    aws_security_group.web_sg.id
  ]

  user_data = file("install_apache.sh")

  tags = {
    Name = "Apache-Server-2"
  }
}

############################
# Output IPs to File
############################

resource "local_file" "server_ips" {

  filename = "server_ips.txt"

  content = <<EOT
Server1 IP: ${aws_instance.server1.public_ip}
Server2 IP: ${aws_instance.server2.public_ip}
EOT
}