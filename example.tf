provider "aws" {
	access_key = ""
	secret_key = ""
	region = "us-east-1"
}

resource "aws_instance" "test_terraform" {
	ami = "ami-b8b061d0"
	instance_type = "t1.micro"
}
