terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

variable "aws_region_name" {}
variable "owner_name" {}
variable "aws_dns_zone_id" {}
variable "aws_dns_zone_domain" {}
variable "ec2_keypair_name" {}
variable "linux_ami_id" {
}
variable "components" {
}
variable "MY_IP" {

}

provider "aws" {
}

data "aws_region" "current" {}


resource "aws_vpc" "my-vpc" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = format("%s-%s", var.owner_name, "test-vpc")
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = format("%s-%s", var.owner_name, "IGW")
  }
}

resource "aws_route_table" "my_rt" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = format("%s-%s", var.owner_name, "RT")
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "192.168.128.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = format("%s-%s", var.owner_name, "subnet")
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.my_rt.id
}

resource "aws_security_group" "kafka_sg" {
  name        = "Kafka_SG"
  description = "Security group for Kafka deployment"
  vpc_id      = aws_vpc.my-vpc.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port   = 9021
    to_port     = 9021
    protocol    = "tcp"
    cidr_blocks = [format("%s/%s", var.MY_IP, "32")]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [format("%s/%s", var.MY_IP, "32")]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  tags = {
    Name = format("%s-%s", var.owner_name, "SG")
  }
}

resource "aws_network_interface" "nics" {
  for_each                = { for i, v in var.components : i => v }
  subnet_id               = aws_subnet.subnet1.id
  private_ip_list_enabled = true
  private_ip_list         = each.value.ip
  security_groups         = [aws_security_group.kafka_sg.id]
  tags = {
    Name       = each.value.name
    owner_name = "sishuo"
  }
}

resource "aws_instance" "servers" {
  //instance_type = var.zk_instance_type
  for_each = { for i, v in var.components : i => v }
  tags = {
    Name       = each.value.name
    owner_name = var.owner_name
    dns_prefix = each.value.dns_prefix
  }
  instance_type = each.value.instance_type

  //if ami is defined in var.components.ami, then use it, else use the default linux ami id
  ami = lookup(each.value, "ami", var.linux_ami_id)
  # ami = contains(each.value, "ami") ? each.value.ami : var.linux_ami_id

  private_dns_name_options {
    enable_resource_name_dns_a_record = true
  }
  network_interface {
    network_interface_id = aws_network_interface.nics[each.key].id
    device_index         = 0
  }
  root_block_device {
    volume_size = each.value.ebs
  }
  key_name = var.ec2_keypair_name
  # associate_public_ip_address = true
}

resource "aws_route53_zone" "my-internal-zone" {
  name = format("%s.%s", var.owner_name, "dev")
  vpc {
    vpc_id = aws_vpc.my-vpc.id
  }
}

output "servers" {
  value = aws_instance.servers
}

resource "aws_route53_record" "dns-public-records" {
  for_each = { for i, v in aws_instance.servers : i => v }
  zone_id  = var.aws_dns_zone_id
  name     = format("%s.%s.%s", each.value.tags.dns_prefix, var.owner_name, var.aws_dns_zone_domain)
  type     = "A"
  ttl      = "30"
  records  = [each.value.public_ip]
  depends_on = [
    aws_instance.servers
  ]
}

resource "aws_route53_record" "dns-internal-records" {
  for_each = { for i, v in aws_instance.servers : i => v }
  zone_id  = aws_route53_zone.my-internal-zone.id
  name     = format("%s.%s", each.value.tags.dns_prefix, aws_route53_zone.my-internal-zone.name)
  type     = "A"
  ttl      = "30"
  records  = [each.value.private_ip]
  depends_on = [
    aws_instance.servers
  ]
}

# create additional dns record for kerberos kdc server
resource "aws_route53_record" "dns-kdc" {
  zone_id  = aws_route53_zone.my-internal-zone.id
  name     = format("%s.%s", "kdc", aws_route53_zone.my-internal-zone.name)
  type     = "A"
  ttl      = "30"
  records  = ["192.168.128.99"]
  depends_on = [
    aws_instance.servers
  ]
}
