provider "aws" {
  region = "ap-south-1"
}

#VPC creation
resource "aws_vpc" "demo-vpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "vpc"
  }
}

#Subnet creation
resource "aws_subnet" "public-subnet" {
  vpc_id            = aws_vpc.demo-vpc.id
  cidr_block       = "192.168.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "Public-subnet"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id            = aws_vpc.demo-vpc.id
  cidr_block       = "192.168.2.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "Private-subnet"
  }
}

#Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.demo-vpc.id

  tags = {
    Name = "Internet-gateway"
  }
}

#Elastic IP creation for NAT gateway
resource "aws_eip" "elastic-ip" {
  domain   = "vpc"
}

#NAT gateway
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.elastic-ip.id
  subnet_id = aws_subnet.public-subnet.id
  tags = {
    Name = "NAT-gateway"
  }
  depends_on = [aws_internet_gateway.igw]
}

#Routing table association
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.demo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Public route"
  }
}

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.demo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gw.id
  }
  tags = {
    Name = "Private route"
  }
}

#Route table association
resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "private_route_table_association" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private_route.id
}

#Security group
resource "aws_security_group" "web-sg" {
  name        = "web-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.demo-vpc.id
  tags = {
    Name = "web-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.web-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.web-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#EC2 creation

resource "aws_instance" "web" {
  ami           = "ami-0f918f7e67a3323f0"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  subnet_id     = aws_subnet.public-subnet.id
  associate_public_ip_address = "true"
  user_data     = <<-EOF
        #!/bin/bash
        sudo apt-get update -y
        sudo apt-get install -y nginx
        sudo systemctl start nginx
        sudo systemctl enable nginx
        echo "Hello from user data!" > /var/www/html/index.html
      EOF
  tags = {
    Name = "web"
  }
}

resource "aws_instance" "db" {
  ami           = "ami-0f918f7e67a3323f0"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  subnet_id     = aws_subnet.private-subnet.id
  tags = {
    Name = "db"
  }
}