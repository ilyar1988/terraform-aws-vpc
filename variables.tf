variable "aws_region" {
	default = "us-east-1"
}

variable "vpc_cidr" {
	default = "172.31.0.0/24"
}

variable "public_sub" {
	type = list
	default = ["172.31.3.0/24","172.31.4.0/24"]
}

variable "private_sub" {
	type = list
	default = ["172.31.103.0/24","172.31.104.0/24"]
}