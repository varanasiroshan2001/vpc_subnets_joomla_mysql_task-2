
// Configure the AWS Provider
provider "aws" {
  region  = "ap-south-1"
  profile = "roshan1"
}


//CREATE A VPC (VIRTUAL PRIVATE CLOUD)
resource "aws_vpc" "mybuilding" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  tags = {
    Name = "main"
  }
}


//MY FIRST SUBNET WITH PUBLIC ACCESS FOR JOOMLA WEBSITE
resource "aws_subnet" "public_subnet" {
  vpc_id     = "${aws_vpc.mybuilding.id}"
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"
  
  tags = {
    Name = "My_public_subnet"
  }
}


//MY SECOND SUBNET WITH PRIVATE ACCESS FOR MYSQL DATABASE 
resource "aws_subnet" "private_subnet" {
  vpc_id     = "${aws_vpc.mybuilding.id}"
  cidr_block = "192.168.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "My_private_subnet"
  }
}

//MY INTERNET GATEWAY TO ALLOW PUBLIC ACCESS AND FOR SNAT AND DNAT OPTIONS
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.mybuilding.id}"

  tags = {
    Name = "mygateway"
  }
  depends_on = [ 
      aws_subnet.public_subnet, 
      aws_subnet.private_subnet ]
}


//ROUTE TABLE FOR MY 1ST SUBNET SO THAT IT CAN GO TO INTERNET AND PUBLIC CAN ACCESS IT THROUGH GATEWAY
resource "aws_route_table" "route" {
  vpc_id = "${aws_vpc.mybuilding.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags = {
    Name = "my_route"
  }
}

//FOR ASSOCIATING OR ATTACHING THE ROUTE TABLE TO THE SUBNET WHICH WE WANT TO
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.route.id
}




//FOR LAUNCHING INSTANCE I CREATE SECURITY GROUP WITH SSH,HTTP INBOUND RULES for mysql instance
resource "aws_security_group" "roshan_grp_r_mysql" {
  name         = "roshan_grp_r"
  description  = "allow ssh and httpd"
  vpc_id = "${aws_vpc.mybuilding.id}"

  ingress {
    description = "SSH Port"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPD Port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 
   ingress {
    description = "Mysql server"
    from_port   = 3306
    to_port     = 3306
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
    Name = "roshan_sec_grp_r_mysql"
  }
}
  
  
//FOR LAUNCHING INSTANCE I CREATE SECURITY GROUP WITH SSH,HTTP INBOUND RULES for wordpress instance
resource "aws_security_group" "roshan_grp_r_joomla" {
  name         = "roshan_grp_r"
  description  = "allow ssh and httpd"
  vpc_id = "${aws_vpc.mybuilding.id}"

  ingress {
    description = "SSH Port"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPD Port"
    from_port   = 80
    to_port     = 80
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
    Name = "roshan_sec_grp_r_joomla"
  }
}


//FOR LAUNCHING INSTANCE THROUGH EC2 FOR JOOMLA
resource "aws_instance" "myosweb" {
  ami           = "ami-0bf4cefb652962d41"
  instance_type = "t2.micro"
  key_name = "ros"
  vpc_security_group_ids = [aws_security_group.roshan_grp_r_joomla.id]
  subnet_id = aws_subnet.public_subnet.id
  tags = {
    Name = "JOOMLAA OS"
    env = "website"
  }
}



//FOR LAUNCHING INSTANCE THROUGH EC2 FOR MYSQL DATABASE
resource "aws_instance" "myosdatabase" {
  ami           = "ami-76166b19"
  instance_type = "t2.micro"
  key_name = "ros"
  vpc_security_group_ids = [aws_security_group.roshan_grp_r_mysql.id]
  subnet_id = aws_subnet.private_subnet.id
  tags = {
    Name = "mysql OS"
    env = "database server"
  }
}
