# Create the VPC
 resource "aws_vpc" "ilya" {                # Creating VPC here
   cidr_block       = var.ilya_vpc_cidr     # Defining the CIDR block use 10.0.0.0/24 for demo
   instance_tenancy = "default"
 }
 #Create Internet Gateway and attach it to VPC
 resource "aws_internet_gateway" "IGW" {    # Creating Internet Gateway
    vpc_id =  aws_vpc.ilya.id               # vpc_id will be generated after we create VPC
 }
 # Create a Public Subnets.
 resource "aws_subnet" "public_1" {    # Creating Public Subnets
   vpc_id =  aws_vpc.ilya.id
   cidr_block = "${var.public_1}"        # CIDR block of public subnets
 }
  resource "aws_subnet" "public_2" {    
   vpc_id =  aws_vpc.ilya.id
   cidr_block = "${var.public_2}"        
 }
 # Create a Private Subnet                   # Creating Private Subnets
 resource "aws_subnet" "private_1" {
   vpc_id =  aws_vpc.ilya.id
   cidr_block = "${var.private_1}"          # CIDR block of private subnets
 }
 resource "aws_subnet" "private_2" {
   vpc_id =  aws_vpc.ilya.id
   cidr_block = "${var.private_2}"          
 }
 # Route table for Public Subnet's
 resource "aws_route_table" "PublicRT" {    # Creating RT for Public Subnet
    vpc_id =  aws_vpc.ilya.id
         route {
    cidr_block = "0.0.0.0/0"               # Traffic from Public Subnet reaches Internet via Internet Gateway
    gateway_id = aws_internet_gateway.IGW.id
     }
 }
 # Route table for Private Subnet's
 resource "aws_route_table" "PrivateRT" {    # Creating RT for Private Subnet
   vpc_id = aws_vpc.ilya.id
   route {
   cidr_block = "0.0.0.0/0"             # Traffic from Private Subnet reaches Internet via NAT Gateway
   nat_gateway_id = aws_nat_gateway.NATgw.id
   }
 }
 # Route table Association with Public Subnet's
 resource "aws_route_table_association" "PublicRTassociation" {
    subnet_id = aws_subnet.public_1.id
    route_table_id = aws_route_table.PublicRT.id
 }
  resource "aws_route_table_association" "PublicRTassociation_2" {
    subnet_id = aws_subnet.public_2.id
    route_table_id = aws_route_table.PublicRT.id
 }
 # Route table Association with Private Subnet's
 resource "aws_route_table_association" "PrivateRTassociation" {
    subnet_id = aws_subnet.private_1.id
    route_table_id = aws_route_table.PrivateRT.id
 }
  resource "aws_route_table_association" "PrivateRTassociation_2" {
    subnet_id = aws_subnet.private_2.id
    route_table_id = aws_route_table.PrivateRT.id
 }
 resource "aws_eip" "nateIP" {
   vpc   = true
 }
 # Creating the NAT Gateway using subnet_id and allocation_id
 resource "aws_nat_gateway" "NATgw" {
   allocation_id = aws_eip.nateIP.id
   subnet_id = aws_subnet.public_1.id
 }