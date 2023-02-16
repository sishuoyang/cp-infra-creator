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
variable "peer_owner_id" {}
variable "owner_name" {}
variable "aws_dns_zone_id" {}
variable "aws_dns_zone_domain" {}
variable "ec2_keypair_name" {}
variable "linux_ami_id" {
}
variable "dcs" {
}
variable "components" {
}
variable "subnets" {

}
variable "MY_IP" {

}

provider "aws" {
}

data "aws_region" "current" {}


resource "aws_vpc" "DCs" {
  for_each             = { for i, v in var.dcs : i => v }
  cidr_block           = each.value.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name  = format("%s-%s", var.owner_name, "${each.value.name}")
    Name1 = each.value.name
  }
}

resource "aws_internet_gateway" "igws" {
  for_each = { for i, v in aws_vpc.DCs : i => v }
  vpc_id   = each.value.id
  tags = {
    Name = format("%s-%s", var.owner_name, "IGW for ${each.value.tags.Name}")
  }
}

resource "aws_vpc_peering_connection" "peerings" {
  for_each      = { for i, v in aws_vpc.DCs : i => v }
  peer_owner_id = var.peer_owner_id
  peer_vpc_id   = aws_vpc.DCs[each.key].id
  vpc_id        = aws_vpc.DCs[(each.key + 1) % 3].id
  auto_accept   = true
  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
  tags = {
    Name = "Peering ${aws_vpc.DCs[each.key].tags.Name}-${aws_vpc.DCs[(each.key + 1) % 3].tags.Name}"
  }
}

# # for ansible control node and ad server
# DC1
resource "aws_route_table" "my_rt0" {
  vpc_id = aws_vpc.DCs[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igws[0].id
  }
  route {
    cidr_block                = "172.16.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.peerings[0].id
  }
  route {
    cidr_block                = "10.0.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.peerings[2].id
  }
  tags = {
    Name = format("%s-%s", var.owner_name, "RT 0")
  }
}
# DC1
resource "aws_route_table" "my_rt1" {
  vpc_id = aws_vpc.DCs[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igws[0].id
  }
  route {
    cidr_block                = "172.16.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.peerings[0].id
  }
  route {
    cidr_block                = "10.0.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.peerings[2].id
  }
  tags = {
    Name = format("%s-%s", var.owner_name, "RT 1")
  }
}

# DC2
resource "aws_route_table" "my_rt2" {
  vpc_id = aws_vpc.DCs[1].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igws[1].id
  }
  route {
    cidr_block                = "192.168.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.peerings[0].id
  }
  route {
    cidr_block                = "10.0.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.peerings[1].id
  }
  tags = {
    Name = format("%s-%s", var.owner_name, "RT 2")
  }
}

#dc 3
resource "aws_route_table" "my_rt3" {
  vpc_id = aws_vpc.DCs[2].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igws[2].id
  }
  route {
    cidr_block                = "192.168.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.peerings[2].id
  }
  route {
    cidr_block                = "172.16.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.peerings[1].id
  }
  tags = {
    Name = format("%s-%s", var.owner_name, "RT 3")
  }
}

# # for ansible control node, ad server etc.
resource "aws_subnet" "subnets" {
  for_each                = { for i, v in var.subnets : i => v }
  vpc_id                  = aws_vpc.DCs[each.value.dcindex].id
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = true
  tags = {
    Name = format("%s-%s", var.owner_name, each.value.name)
  }
}


resource "aws_route_table_association" "a0" {
  subnet_id      = aws_subnet.subnets[0].id
  route_table_id = aws_route_table.my_rt0.id
}

resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.subnets[1].id
  route_table_id = aws_route_table.my_rt1.id
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.subnets[2].id
  route_table_id = aws_route_table.my_rt2.id
}
resource "aws_route_table_association" "a3" {
  subnet_id      = aws_subnet.subnets[3].id
  route_table_id = aws_route_table.my_rt3.id
}

resource "aws_security_group" "kafka_sgs" {
  for_each    = { for i, v in aws_vpc.DCs : i => v }
  name        = "Kafka_SG_${each.value.tags.Name}"
  description = "Security group for Kafka deployment"
  vpc_id      = each.value.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.0.0/16", "172.16.0.0/16", "10.0.0.0/16"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [format("%s/%s", var.MY_IP, "32")]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  tags = {
    Name = format("%s-%s", var.owner_name, "SG ${each.value.tags.Name}")
  }
}


resource "aws_network_interface" "nics" {
  for_each                = { for i, v in var.components : i => v }
  subnet_id               = aws_subnet.subnets[each.value.subnetindex].id
  private_ip_list_enabled = true
  private_ip_list         = each.value.ip
  security_groups         = [aws_security_group.kafka_sgs[each.value.dcindex].id]
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
    dcindex    = each.value.dcindex
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
    vpc_id = aws_vpc.DCs[0].id
  }
  vpc {
    vpc_id = aws_vpc.DCs[1].id
  }
  vpc {
    vpc_id = aws_vpc.DCs[2].id
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
