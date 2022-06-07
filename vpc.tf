resource "aws_vpc" "terra_vpc" {
  cidr_block       = var.vpc_cidr
  tags = {
    Name = "TerraVPC"
  }
}

# Subnets : public
resource "aws_subnet" "public" {
  count = length(var.public_sub)
  vpc_id = aws_vpc.terra_vpc.id
  cidr_block = element(var.public_sub,count.index)
  # availability_zone = element(var.azs,count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet-${count.index+1}"
  }
}

# Subnets : private
resource "aws_subnet" "private" {
  count = length(var.private_sub)
  vpc_id = aws_vpc.terra_vpc.id
  cidr_block = element(var.private_sub,count.index)
  # availability_zone = element(var.azs,count.index)
  # map_private_ip_on_launch = true
  tags = {
    Name = "Subnet-${count.index+1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "terra_igw" {
  vpc_id = aws_vpc.terra_vpc.id
  tags = {
    Name = "ilya-vpc"
  }
}

# Route table: attach Internet Gateway 
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.terra_vpc.id
  route {
    cidr_block = "172.31.0.0/24"
    gateway_id = aws_internet_gateway.terra_igw.id
  }
  tags = {
    Name = "publicRouteTable"
  }
}

# Internet Gateway for the public subnet
resource "aws_internet_gateway" "test-igw" {
  vpc_id = aws_vpc.terra_vpc.id
}

# Route table association with public subnets
resource "aws_route_table_association" "a" {
  count = length(var.public_sub)
  subnet_id      = element(aws_subnet.public.*.id,count.index)
  route_table_id = aws_route_table.public_rt.id
}

# Create a NAT gateway with an Elastic IP for each private subnet to get internet connectivity
resource "aws_eip" "test-eip" {
  # count    = length(var.private_sub)
  vpc        = true
  depends_on = [aws_internet_gateway.test-igw]
}

resource "aws_nat_gateway" "test-natgw" {
  allocation_id = aws_eip.test-eip.id
  subnet_id     = element(aws_subnet.public.*.id, 0)
  depends_on    = [aws_internet_gateway.test-igw]
    tags = {
      Name = "nat"
  }
}

# Create a new route table for the private subnets, make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.terra_vpc.id

  route {
    cidr_block     = "172.31.0.0/24"
    nat_gateway_id = aws_nat_gateway.test-natgw.id
  }
    tags = {
      Name = "privateRouteTable"
  }
}

# Explicitly associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "b" {
  count          = length(var.private_sub)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private_rt.id
}

/*==== VPC's Default Security Group ======*/
resource "aws_security_group" "Ilya-sg" {
  name        = "Ilya-sg"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = "${aws_vpc.terra_vpc.id}"
  depends_on  = [aws_vpc.terra_vpc]
  ingress {
    from_port = "80"
    to_port   = "80"
    protocol  = "tcp"
    cidr_blocks = aws_vpc.terra_vpc.vpc_cidr
  }
  
  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web-1" {
    #ami = "${data.aws_ami.my_ami.id}"
    ami = "ami-0d857ff0f5fc4e03b"
    availability_zone = "us-east-1a"
    instance_type = "t2.micro"
    key_name = "LaptopKey"
    subnet_id = "${aws_subnet.private_sub.id}"
    vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
    associate_public_ip_address = true	
    tags = {
        Name = "Server-1"
        Env = "QA"
        Owner = "Ilya"
    }
}