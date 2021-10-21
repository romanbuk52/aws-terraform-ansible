terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "eu-central-1"
}

resource "aws_instance" "nginx_server" {
  count = var.instance_count
  ami           = "ami-0245697ee3e07e755"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["sg-03f44077"]
  key_name = "ansible"
  tags = {
    Name = "Terraform-${count.index + 1}"
  }
}
#ebs volume created
resource "aws_ebs_volume" "ebs"{
  count = var.instance_count
  availability_zone =  aws_instance.nginx_server[count.index].availability_zone
  size              = 10
  tags = {
    Name = "terraform"
  }
}
#ebs volume attatched to instance
resource "aws_volume_attachment" "ebs_att" {
  count = var.instance_count
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs[count.index].id
  instance_id = aws_instance.nginx_server[count.index].id
  force_detach = true
}

resource "local_file" "ip" {
    count = var.instance_count
    content  = aws_instance.nginx_server[count.index].public_ip
    filename = "ip-${count.index}.txt"
}

variable "instance_count" {
  default = "2"
}

output "ec2_public_ip" {
  value = aws_instance.nginx_server[*].public_ip
}

# # ------------------------Login and provisioning------------------------------------
# resource "null_resource" "nullremote2" {
# depends_on = [aws_volume_attachment.ebs_att]  
# connection {
# 	type     = "ssh"
#   user        = "root"
#   private_key = "${file(var.ssh_key_private)}"
# }
# # command to run ansible playbook on remote Linux OS
# provisioner "remote-exec" {
    
#     inline = [
# 	"cd /root/ansible_terraform/aws_instance/",
# 	"ansible-playbook instance.yml"
# ]
# }
# provisioner "local-exec" {
#     command = "ansible-playbook -u root -i '${self.public_ip},' --private-key ${var.ssh_key_private} provision.yml"
#   }

# }

# variable "ssh_key_private" {
#   default = "./ansible"
# }