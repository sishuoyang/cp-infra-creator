aws_region_name = "ap-southeast-1"
owner_name      = "sishuo" #make sure this can be used as part of dns domain
peer_owner_id   = "492737776546" #this is the account Id. You can get it from Aws console -> top right (click your user name)-> account -> account id
# This is the public Route53 Zone for ps.confluent-internal.io
# The script adds a record for each server to the zone using this naming convention: "{dns_prefix}.{owner_name}.{aws_dns_zone_domain}"
aws_dns_zone_id     = "xxxxx"
aws_dns_zone_domain = "my.example.com"
ec2_keypair_name    = "my-keypair"

# Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
# linux_ami_id           = "ami-0f62d9254ca98e1aa"

# Red Hat Enterprise Linux 8 (HVM), SSD Volume Type, with JAVA17 installed & cp tar ball
# this can be public AMI or your own AMI
linux_ami_id = "ami-xxxx"

# Ubuntu Server 20.04 LTS (HVM), SSD Volume Type
# linux_ami_id           = "ami-00e912d13fbb4f225"


dcs = [
  {
    name = "dc1"
    cidr = "192.168.0.0/16"
  },
  {
    name = "dc2"
    cidr = "172.16.0.0/16"
  },
  {
    name = "dc3"
    cidr = "10.0.0.0/16"
  },
]

subnets = [
  {
    name    = "subnet0"
    cidr    = "192.168.192.0/24"
    dcindex = 0
  },
  {
    name    = "subnet1"
    cidr    = "192.168.128.0/24"
    dcindex = 0
  },
  {
    name    = "subnet2"
    cidr    = "172.16.128.0/24"
    dcindex = 1
  },
  {
    name    = "subnet3"
    cidr    = "10.0.128.0/24"
    dcindex = 2
  }
]

components = [
  # {
  #   instance_type = "t3.micro"
  #   name          = "sishuo-ansible",
  #   dns_prefix    = "jump"
  #   ip            = ["192.168.192.100"]
  #   ebs           = "50"
  #   ami           = "ami-04968485dd11b9e88"
  #   dc            = "dc1"
  #   subnetindex   = 0
  #   dcindex       = 0
  # },
  {
    instance_type = "t3.small"
    name          = "sishuo-ad",
    dns_prefix    = "ad"
    ip            = ["192.168.192.99"]
    ebs           = "50"
    ami           = "ami-07e8f353d7d5fbe89"
    dc            = "dc1"
    subnetindex   = 0
    dcindex       = 0
  },
  {
    instance_type = "t2.medium"
    name          = "sishuo-grafana"
    dns_prefix    = "grafana"
    ip            = ["192.168.192.101"]
    ebs           = "50",
    ami           = "ami-002e75c219ead05df",
    dc            = "dc1"
    subnetindex   = 0
    dcindex       = 0
  },
  {
    instance_type = "t3.medium"
    name          = "sishuo-zk1",
    dns_prefix    = "z1"
    ip            = ["192.168.128.10"]
    ebs           = "50"
    dc            = "dc1"
    subnetindex   = 1
    dcindex       = 0
  },
  {
    instance_type = "t3.medium"
    name          = "sishuo-zk2",
    dns_prefix    = "z2"
    ip            = ["192.168.128.11"]
    ebs           = "50"
    dc            = "dc1"
    subnetindex   = 1
    dcindex       = 0
  },
  {
    instance_type = "t3.medium"
    name          = "sishuo-zk3"
    dns_prefix    = "z3"
    ip            = ["172.16.128.10"]
    ebs           = "50"
    dc            = "dc2"
    subnetindex   = 2
    dcindex       = 1
  },
  {
    instance_type = "t3.medium"
    name          = "sishuo-zk4"
    dns_prefix    = "z4"
    ip            = ["172.16.128.11"]
    ebs           = "50"
    dc            = "dc2"
    subnetindex   = 2
    dcindex       = 1
  },
  {
    instance_type = "t3.medium"
    name          = "sishuo-zk5"
    dns_prefix    = "z5"
    ip            = ["10.0.128.12"]
    ebs           = "50"
    dc            = "dc3"
    subnetindex   = 3
    dcindex       = 2
  },
  {
    instance_type = "r6i.large"
    name          = "sishuo-b1"
    dns_prefix    = "b1"
    ip            = ["192.168.128.20"]
    ebs           = "50"
    subnetindex   = 1
    dcindex       = 0
  },
  {
    instance_type = "r6i.large"
    name          = "sishuo-b2"
    dns_prefix    = "b2"
    ip            = ["192.168.128.21"]
    ebs           = "50"
    subnetindex   = 1
    dcindex       = 0
  },
  {
    instance_type = "r6i.large"
    name          = "sishuo-b3"
    dns_prefix    = "b3"
    ip            = ["192.168.128.22"]
    ebs           = "50"
    subnetindex   = 1
    dcindex       = 0
  },
  {
    instance_type = "r6i.large"
    name          = "sishuo-b4"
    dns_prefix    = "b4"
    ip            = ["172.16.128.20"]
    ebs           = "50"
    subnetindex   = 2
    dcindex       = 1
  },
  {
    instance_type = "r6i.large"
    name          = "sishuo-b5"
    dns_prefix    = "b5"
    ip            = ["172.16.128.21"]
    ebs           = "50"
    subnetindex   = 2
    dcindex       = 1
  },
  {
    instance_type = "r6i.large"
    name          = "sishuo-b6"
    dns_prefix    = "b6"
    ip            = ["172.16.128.22"]
    ebs           = "50"
    subnetindex   = 2
    dcindex       = 1
  },
  {
    instance_type = "t2.medium"
    name          = "sishuo-sr1"
    dns_prefix    = "sr1"
    ip            = ["192.168.128.30"]
    ebs           = "50"
    subnetindex   = 1
    dcindex       = 0
  },
  # {
  #   instance_type = "t2.medium"
  #   name          = "sishuo-sr2"
  #   dns_prefix    = "sr2"
  #   ip            = ["172.16.128.31"]
  #   ebs           = "50"
  #   subnetindex   = 2
  #   dcindex       = 1
  # },
  {
    instance_type = "t2.medium"
    name          = "sishuo-connect"
    dns_prefix    = "con1"
    ip            = ["192.168.128.41"]
    ebs           = "50"
    subnetindex   = 1
    dcindex       = 0
  },
  # {
  #   instance_type = "t2.medium"
  #   name          = "sishuo-connect"
  #   dns_prefix    = "con2"
  #   ip            = ["172.16.128.42"]
  #   ebs           = "50"
  #   subnetindex   = 2
  #   dcindex       = 1
  # },
  {
    instance_type = "t2.medium"
    name          = "sishuo-ksql"
    dns_prefix    = "ksql1"
    ip            = ["192.168.128.60"]
    ebs           = "50"
    subnetindex   = 1
    dcindex       = 0
  },
  {
    instance_type = "t2.large"
    name          = "sishuo-ccc"
    dns_prefix    = "ccc"
    ip            = ["172.16.128.51"]
    ebs           = "50"
    subnetindex   = 2
    dcindex       = 1
  }
]
