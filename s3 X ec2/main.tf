provider "aws" {
    region = var.region
}

resource "aws_s3_bucket" {
    bucket = var.mikoskytech
    acl = "private"
}

resource "aws_s3_bucket_object" "object1" {
    for_each = fileset("html/", "*")
    bucket = aws_s3_bucket.mikoskytech.id
    key = each.value
    source = "html/${each.value}"
    etag = filemd5("html/${each.value}")
    content_type = "text/html"
}

resource "aws_instance" "web" {
    ami = "ami-0c02fb55956c7d316"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.web-sg.id]
    iam_instance_profile = aws_iam_instance_profile.SSMRoleForEC2.name
    user_data = <<EOF

    #!/bin/bash
    # install httpd (Linux 2 version)
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello Mikosky World from $(hostname -f)</h1>" > /var/www/html/index.html
    EOF

    tags = {
        Name = "mikosky-ec2-instance"
    }
}

resource "aws_security_group" "web-sg" {
  name = "Web-SG"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "SSMRoleForEC2" {
    name = "SSMRoleForEC2"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "SSMRoleForEC2" {
    name = "SSMRoleForEC2"
    role = aws_iam_role.SSMRoleForEC2.name
}

resource "aws_iam_role_policy_attachment" "role-policy-attachment" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", 
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ])

  role       = aws_iam_role.SSMRoleForEC2.name
  policy_arn = each.value
}

    