provider "aws" {
	access_key = ""
	secret_key = ""
	region = "us-east-1"
}

resource "aws_instance" "test_terraform" {
	ami = "ami-408c7f28"
	instance_type = "t1.micro"
}
