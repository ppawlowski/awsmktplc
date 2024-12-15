packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "source_ami" {
  type    = string
  default = "ami-0453ec754f44f9a4a"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

source "amazon-ebs" "amazon-linux" {
  region        = var.aws_region
  source_ami    = var.source_ami
  instance_type = var.instance_type
  
  ssh_username  = "ec2-user"
  ami_name      = "custom-ami-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  
  ami_description = "Custom Amazon Linux 2 AMI built with Packer"
  
  tags = {
    Name       = "custom-packer-ami"
    BuildTime  = formatdate("YYYY-MM-DD hh:mm:ss", timestamp())
    Creator    = "Packer"
  }
}

build {
  sources = ["source.amazon-ebs.amazon-linux"]

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y docker",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo yum install -y nginx",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      "sudo yum install -y git",
      "sudo yum install -y python3",
      "sudo rm -f /home/ec2-user/.ssh/authorized_keys /root/.ssh/authorized_keys /etc/ssh/*key*"
    ]
  }

  post-processor "manifest" {
    output     = "packer-manifest.json"
    strip_path = true
  }
}
