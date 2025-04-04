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

user_data =
#!/bin/bash

# Update system and install required dependencies
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y curl wget unzip git build-essential

# Install Node.js (Latest LTS version)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Start and enable PostgreSQL
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Create Medusa database and user
sudo -u postgres psql <<EOF
CREATE DATABASE medusa;
CREATE USER medusa_user WITH ENCRYPTED PASSWORD 'medusa_pass';
ALTER ROLE medusa_user WITH SUPERUSER;
GRANT ALL PRIVILEGES ON DATABASE medusa TO medusa_user;
EOF

# Install Redis (For caching)
sudo apt install -y redis
sudo systemctl enable redis
sudo systemctl start redis

# Install Medusa CLI
npm install -g @medusajs/medusa-cli

# Create Medusa project
cd /home/ubuntu
medusa new my-medusa-store --seed

# Set up database configuration
cat <<EOT >> /home/ubuntu/my-medusa-store/.env
DATABASE_URL=postgres://medusa_user:medusa_pass@localhost:5432/medusa
REDIS_URL=redis://localhost:6379
JWT_SECRET=mysecret
COOKIE_SECRET=mycookiesecret
EOT

# Change ownership to ubuntu user
chown -R ubuntu:ubuntu /home/ubuntu/my-medusa-store

# Start Medusa in the background
cd /home/ubuntu/my-medusa-store
nohup medusa develop > /home/ubuntu/medusa.log 2>&1 

  tags = {
    Name = "Medusa-Server"
  }
}

output "medusa_instance_ip" {
  value = aws_instance.medusa.public_ip
}
