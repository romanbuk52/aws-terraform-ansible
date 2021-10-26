terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

data "aws_vpc" "default" {
  default = true
}
resource "aws_security_group" "allow_ssh" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nginx_server" {
  ami           = "ami-0245697ee3e07e755" # image debian
  # ami = "ami-05f7491af5eef733a" # image ubuntu
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  key_name = "ansible"
  tags = {
    Name = "Terraform"
  }
}
# ------------------ebs volume create
resource "aws_ebs_volume" "ebs"{
  availability_zone =  aws_instance.nginx_server.availability_zone
  size              = 10
  tags = {
    Name = "terraform"
  }
}
# -------------------ebs volume attatched to instance
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs.id
  instance_id = aws_instance.nginx_server.id
  force_detach = true
}


output "public_ip" {
  value = aws_instance.nginx_server.public_ip
}

# # ------------------------Login and provisioning------------------------------------
resource "null_resource" "provisioning" {
depends_on = [aws_instance.nginx_server] 
  provisioner "remote-exec" {
    connection {
      host = aws_instance.nginx_server.public_ip
      type     = "ssh"
      user        = "admin"
      private_key = "${file(var.ssh_key_private)}"
    }
      inline = [
      "echo \"Hello World!\""
      ]
  }

# command to run ansible playbook on remote Linux OS
  provisioner "local-exec" {
    command = "ansible-playbook -u admin -i '${aws_instance.nginx_server.public_ip},' --private-key ${var.ssh_key_private} ./ansible/instanse_ansible.yml"
  }
}

variable "ssh_key_private" {
  default = "./ansible.pem"
}

# ---------------------provision IP on HTML pages------------------------------------
resource "null_resource" "provisioning_ip" {
  depends_on = [null_resource.provisioning]
  provisioner "remote-exec" {
    connection {
      host = aws_instance.nginx_server.public_ip
      type     = "ssh"
      user        = "admin"
      private_key = "${file(var.ssh_key_private)}"
    }
      inline = [
      "sudo sed -i  '/server ip =/a ${aws_instance.nginx_server.public_ip}' /home/admin/html/index.html"
      ]
  }
}