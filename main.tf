provider "aws" {
  region = "us-west-2"
}

resource "aws_key_pair" "aws_ssh_key" {
  key_name   = "aws-ssh-key"
  public_key = file("~/.ssh/aws-ssh-key.pub") # Replace with the path to your public key
}

resource "aws_instance" "docker_ec2" {
  ami           = "ami-04dd23e62ed049936" # Canonical, Ubuntu, 24.04, amd64 noble image
  instance_type = "t2.micro"
  key_name      = aws_key_pair.aws_ssh_key.key_name

  security_groups = [aws_security_group.docker_ec2_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io
              systemctl start docker
              usermod -a -G docker ubuntu
              
              # Run the Docker image initially
              docker run -d \
                -e GRADIO_SERVER_NAME=0.0.0.0 \
                -e GRADIO_SERVER_PORT=7860 \
                -p 7860:7860 -it --rm \
                ghcr.io/cinnamon/kotaemon:main-full

              # Install upgrade script
              cat <<'SCRIPT' > /usr/local/bin/upgrade_docker_image.sh
              #!/bin/bash
              FORCE=false
              if [[ "$1" == "--force" ]]; then
                FORCE=true
              fi
              
              # Check if a newer image exists or if force option is provided
              docker pull ghcr.io/cinnamon/kotaemon:main-full
              if [[ $(docker images -q ghcr.io/cinnamon/kotaemon:main-full) != $(docker ps --filter ancestor=ghcr.io/cinnamon/kotaemon:main-full --format "{{.Image}}") || "$FORCE" == true ]]; then
                echo "Stopping existing container..."
                docker stop $(docker ps -q --filter ancestor=ghcr.io/cinnamon/kotaemon:main-full)
                
                echo "Starting new container..."
                docker run -d \
                  -e GRADIO_SERVER_NAME=0.0.0.0 \
                  -e GRADIO_SERVER_PORT=7860 \
                  -p 7860:7860 -it --rm \
                  ghcr.io/cinnamon/kotaemon:main-full
              else
                echo "No new image available or FORCE not provided."
              fi
              SCRIPT

              chmod +x /usr/local/bin/upgrade_docker_image.sh
              EOF

  tags = {
    Name = "docker-ec2"
  }

  provisioner "local-exec" {
    command = "echo EC2 Instance Public IP: ${self.public_ip}"
  }

  provisioner "local-exec" {
    command = "echo EC2 Instance Public DNS: ${self.public_dns}"
  }
}

output "ec2_public_ip" {
  value = aws_instance.docker_ec2.public_ip
  description = "The public IP address of the EC2 instance."
}

output "ec2_public_dns" {
  value = aws_instance.docker_ec2.public_dns
  description = "The public DNS of the EC2 instance."
}

resource "aws_security_group" "docker_ec2_sg" {
  name_prefix = "docker_ec2_sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere. Adjust as needed.
  }

  ingress {
    from_port   = 7860
    to_port     = 7860
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access to the Gradio server from anywhere. Adjust as needed.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}