terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket = "hassan900"
    key    = "aws/ec2-deploy/terraform.tfstate"
    region = "us-east-1" # Make sure to include region here!
  }
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "server" {
  ami                    = "ami-084568db4383264d4"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.maingroup.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2-profile.name

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = var.private_key
    timeout     = "4m"
  }

  tags = {
    Name = "DeployVM"
  }
}

resource "aws_iam_instance_profile" "ec2-profile" {
  name = "ec2-profile"
  role = "EC2-ECR-AUTH"
}

resource "aws_security_group" "maingroup" {
  name        = "main-sg"
  description = "Main security group"

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9X9oMRnsmby3tPfXLYOCKkX2m24iYBIhAzHvm+KOsUa/dM8C12/1sZKvUekMzCJNe2QK5QorSeed88eDDnsogHYlSIM0Ka/OfcOsJommPKQpkK+XZidv7aSmtSmD9MHG02ivx9i1kTxZzDFT25LEW8rvuZUYe3VueTd0l9Sghq7EIn5AmQxNd/zbEqk5Y4Rx6rrM7042ETr2+W8DaC1j4MbLxuPGV33rlu+JUmhf6hU0ku8hyeUkd5itSbrkbBf1EA92BCt9Q9e7yBgFccPjtXTdNbvQetUMppD/LKfRM9s0Lgie0Rsac4iNP4s2wOeOVN/eTYfH7cP6HcNltc3U1"
}

output "instance_public_ip" {
  value     = aws_instance.server.public_ip
  sensitive = true
}
