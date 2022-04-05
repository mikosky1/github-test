provider "aws" {
    region = "us-east-1"

}

resource "aws_instance" "db" {
    ami = "ami-0c02fb55956c7d316"
    instance_type = "t2.micro"
    tags = {
        Name = "DB server"
    }
}

resource "aws_instance" "web" {
    ami = "ami-0c02fb55956c7d316"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.web_traffic.name]
    user_data = file("server-script.sh")
    tags = {
        Name = "web server"
    }
}

resource "aws_eip" "web_ip" {
    instance = aws_instance.web.id    
}

variable "ingress" {
    type = list(number)
    default = [80,443]
}

variable "egress" {
    type = list(number)
    default = [80,443]
}

resource "aws_security_group" "web_traffic" {
    name = "Allow Web Traffic"

        dynamic "ingress" {
        iterator = port
        for_each = var.ingress
        content {
            from_port = port.value
            to_port   = port.value
            protocol  = "TCP"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }
        dynamic "egress" {
        iterator = port
        for_each = var.egress
        content {
            from_port   = port.value
            to_port     = port.value
            protocol    = "TCP"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }
}

output "privateIP" {
    value = aws_instance.db.private_ip
}

output "publicIP" {
    value = aws_eip.web_ip.public_ip
}

