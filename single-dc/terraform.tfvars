aws_region_name = "ap-southeast-1"
owner_name      = "sishuo" #make sure this can be used as part of dns domain

# This is the public Route53 Zone for ps.confluent-internal.io
# The script adds a record for each server to the zone using this naming convention: "{dns_prefix}.{owner_name}.{aws_dns_zone_domain}"
aws_dns_zone_id     = "Z267DABJTL4JFI"
aws_dns_zone_domain = "ps.confluent-internal.io"
ec2_keypair_name    = "sishuo-keypair-sg"

# Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
# linux_ami_id           = "ami-0f62d9254ca98e1aa"

# Red Hat Enterprise Linux 8 (HVM), SSD Volume Type
linux_ami_id = "ami-0f1204eaabe751007"

# Ubuntu Server 20.04 LTS (HVM), SSD Volume Type
# linux_ami_id           = "ami-00e912d13fbb4f225"

# sishuo ansible AMI
# ami-0c01e25de0ea167ef

components = [
  {
    instance_type = "t3.micro"
    name          = "sishuo-ansible",
    dns_prefix    = "jump"
    ip            = ["192.168.128.100"]
    ebs           = "50"
    ami           = "ami-04968485dd11b9e88"
  }
  # {
  #   instance_type = "t3.small"
  #   name          = "sishuo-ad",
  #   dns_prefix    = "ad"
  #   ip            = ["192.168.128.99"]
  #   ebs           = "50"
  #   ami           = "ami-07e8f353d7d5fbe89"
  # },
    # {
  #   instance_type = "t3.small"
  #   name          = "sishuo-grafana",
  #   dns_prefix    = "grafana"
  #   ip            = ["192.168.128.102"]
  #   ebs           = "50"
  #   ami           = "ami-002e75c219ead05df"
  # }
  # ,
  # {
  #   instance_type = "t3.medium"
  #   name          = "sishuo-zk1",
  #   dns_prefix    = "z1"
  #   ip            = ["192.168.128.10"]
  #   ebs           = "20"
  # },
  # {
  #   instance_type = "t3.medium"
  #   name          = "sishuo-zk2",
  #   dns_prefix    = "z2"
  #   ip            = ["192.168.128.11"]
  #   ebs           = "20"
  # }
  # , {
  #   instance_type = "t3.medium"
  #   name          = "sishuo-zk3"
  #   dns_prefix    = "z3"
  #   ip            = ["192.168.128.12"]
  #   ebs           = "20"
  # },
  # {
  #   instance_type = "r6i.large"
  #   name          = "sishuo-b1"
  #   dns_prefix    = "b1"
  #   ip            = ["192.168.128.20"]
  #   ebs           = "50"
  # },
  # {
  #   instance_type = "r6i.large"
  #   name          = "sishuo-b2"
  #   dns_prefix    = "b2"
  #   ip            = ["192.168.128.21"]
  #   ebs           = "50"
  # }
  # {
  #   instance_type = "r6i.large"
  #   name          = "sishuo-b3"
  #   dns_prefix    = "b3"
  #   ip            = ["192.168.128.22"]
  #   ebs           = "50"
  # },
  # {
  #   instance_type = "t2.medium"
  #   name          = "sishuo-sr1"
  #   dns_prefix    = "sr1"
  #   ip            = ["192.168.128.30"]
  #   ebs           = "20"
  # },
  # {
  #   instance_type = "t2.medium"
  #   name          = "sishuo-sr2"
  #   dns_prefix    = "sr2"
  #   ip            = ["192.168.128.31"]
  #   ebs           = "20"
  # },
  # {
  #   instance_type = "t2.medium"
  #   name          = "sishuo-connect"
  #   dns_prefix    = "con1"
  #   ip            = ["192.168.128.41"]
  #   ebs           = "20"
  # },
  # {
  #   instance_type = "t2.medium"
  #   name          = "sishuo-connect"
  #   dns_prefix    = "con2"
  #   ip            = ["192.168.128.42"]
  #   ebs           = "20"
  # },
  # {
  #   instance_type = "t2.medium"
  #   name          = "sishuo-ksql"
  #   dns_prefix    = "ksql1"
  #   ip            = ["192.168.128.60"]
  #   ebs           = "20"
  # }
  # {
  #   instance_type = "t2.large"
  #   name          = "sishuo-ccc"
  #   dns_prefix    = "ccc"
  #   ip            = ["192.168.128.51"]
  #   ebs           = "50"
  # }
]
