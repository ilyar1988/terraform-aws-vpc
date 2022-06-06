variable "aws_region" {
	default = "us-east-1"
}

variable "vpc_cidr" {
	default = "10.20.0.0/16"
}

variable "public_sub" {
	type = list
	default = ["172.31.3.0/24","172.31.4.0/24"]
}