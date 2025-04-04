provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_security_group" "medusa_sg" {
  name        = "medusa-security-group"
  description = "Allow HTTP, HTTPS, and Medusa API traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SSH (Restrict in production)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # HTTP
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # HTTPS
  }

  ingress {
    from_port   = 7000
    to_port     = 7000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Medusa API
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "medusa" {
  ami                    = "ami-026c39f4021df9abe" # Amazon Linux 2 (Update as needed)
  instance_type          = "t3.medium"
  key_name               = "keypair2"
  vpc_security_group_ids = [aws_security_group.medusa_sg.id]

user_data = file("test.sh")
  tags = {
    Name = "Medusa-Server"
  }
}

output "medusa_instance_ip" {
  value = aws_instance.medusa.public_ip
}
