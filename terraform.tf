provider "aws" {
  region = "ap-northeast-1" # Change as needed
}

resource "aws_key_pair" "medusa_key" {
  key_name   = "keypair2"
  public_key = "~/.ssh/id_rsa.pub" # Update with your SSH key path
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
  ami                    = "ami-0b6e7ccaa7b93e898" # Amazon Linux 2 (Update as needed)
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.medusa_key.key_name
  vpc_security_group_ids = [aws_security_group.medusa_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras enable postgresql14
    yum install -y postgresql-server postgresql-contrib nodejs npm git

    # Start PostgreSQL
    sudo postgresql-setup --initdb
    sudo systemctl start postgresql
    sudo systemctl enable postgresql

    # Create Medusa Database
    sudo -u postgres psql -c "CREATE DATABASE medusa;"
    sudo -u postgres psql -c "CREATE USER medusauser WITH PASSWORD 'medusapass';"
    sudo -u postgres psql -c "ALTER DATABASE medusa OWNER TO medusauser;"

    # Install Medusa
    npm install -g @medusajs/medusa-cli
    mkdir /home/ec2-user/medusa && cd /home/ec2-user/medusa
    medusa new my-medusa-store --seed
    cd my-medusa-store
    npm install
    npm run start &

  EOF

  tags = {
    Name = "Medusa-Server"
  }
}

output "medusa_instance_ip" {
  value = aws_instance.medusa.public_ip
}
