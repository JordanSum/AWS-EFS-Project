terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.4.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "instance-az-a" {
  ami           = var.ami_id
  instance_type = var.instance_type
  availability_zone = "us-west-2a"

  network_interface {
    network_interface_id = aws_network_interface.NIC-A.id
    device_index         = 0
  }

    user_data = <<-EOF
              #!/bin/bash
              # SSM Agent and EFS Utils Installation Script
              
              # Wait for system to stabilize and network to be ready
              echo "Waiting for system stabilization..."
              sleep 60
              
              # Wait for internet connectivity
              echo "Testing internet connectivity..."
              for i in {1..20}; do
                  if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
                      echo "Internet connectivity confirmed after $i attempts"
                      break
                  fi
                  echo "Waiting for internet connectivity... attempt $i/20"
                  sleep 15
              done
              
              # Download with retries
              for i in {1..5}; do
                  if sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm; then
                      echo "SSM Agent installed successfully on attempt $i"
                      break
                  fi
                  echo "Installation failed, retrying... attempt $i/5"
                  sleep 10
              done
              
              # Enable and start the service
              
              sudo systemctl enable amazon-ssm-agent
              sudo systemctl start amazon-ssm-agent

              # Install EFS Utils
              sudo dnf install -y amazon-efs-utils

              # Create a mount point directory
              sudo mkdir /terraform-efs

              # Set permissions to allow all users read, write, and execute access (not recommended for production)
              sudo chmod 777 /terraform-efs

              # Wait a moment before mounting (ensuring efs is ready)
              sleep 60

              # Mount EFS filesystem (same EFS as az-a)
              sudo mount -t efs -o tls ${var.efs_id}:/ /terraform-efs

              # Create test file in EFS
              sudo bash -c 'echo "This is a test file from instance-az-a." > /terraform-efs/testfile.txt'

              EOF

  tags = {
    Name = "compute-instance-az-a"
  }
}

resource "aws_instance" "instance-az-b" {
  ami           = var.ami_id
  instance_type = var.instance_type
  availability_zone = "us-west-2b"

  network_interface {
    network_interface_id = aws_network_interface.NIC-B.id
    device_index         = 0
  }

      user_data = <<-EOF
              #!/bin/bash
              # SSM Agent and EFS Utils Installation Script
              
              # Wait for system to stabilize and network to be ready
              echo "Waiting for system stabilization..."
              sleep 60
              
              # Wait for internet connectivity
              echo "Testing internet connectivity..."
              for i in {1..20}; do
                  if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
                      echo "Internet connectivity confirmed after $i attempts"
                      break
                  fi
                  echo "Waiting for internet connectivity... attempt $i/20"
                  sleep 15
              done
              
              # Download with retries
              for i in {1..5}; do
                  if sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm; then
                      echo "SSM Agent installed successfully on attempt $i"
                      break
                  fi
                  echo "Installation failed, retrying... attempt $i/5"
                  sleep 10
              done
              
              # Enable and start the service
              
              sudo systemctl enable amazon-ssm-agent
              sudo systemctl start amazon-ssm-agent

              # Install EFS Utils
              sudo dnf install -y amazon-efs-utils

              # Create the same mount point directory as instance in AZ A
              sudo mkdir /terraform-efs

              # Set permissions to allow all users read, write, and execute access (not recommended for production)
              sudo chmod 777 /terraform-efs

              # Wait a moment before mounting (ensuring efs is ready)
              sleep 60

              # Mount EFS filesystem (same EFS as az-a)
              sudo mount -t efs -o tls ${var.efs_id}:/ /terraform-efs

              # Create test file in EFS
              sudo bash -c 'echo "This is a test file from instance-az-b." >> /terraform-efs/testfile.txt'

              EOF

  tags = {
    Name = "compute-instance-az-b"
  }
}

resource "aws_network_interface" "NIC-A" {
  subnet_id       = var.subnet_az_a
  private_ips    = ["192.168.10.10"]
}

resource "aws_network_interface" "NIC-B" {
  subnet_id       = var.subnet_az_b
  private_ips    = ["192.168.20.10"]
}

# Elastic IP for instance in AZ A (ssm_test_3)
resource "aws_eip" "az-a" {
  domain            = "vpc"
  network_interface = aws_network_interface.NIC-A.id
  depends_on        = [aws_instance.instance-az-a]

  tags = {
    Name = "eip_az_a"
  }
}

# Elastic IP for instance in AZ B (ssm_test_4)
resource "aws_eip" "az-b" {
  domain            = "vpc"
  network_interface = aws_network_interface.NIC-B.id
  depends_on        = [aws_instance.instance-az-b]

  tags = {
    Name = "eip_az_b"
  }
}

