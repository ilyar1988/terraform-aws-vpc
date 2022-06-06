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
  # count      = length(var.private_sub)
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