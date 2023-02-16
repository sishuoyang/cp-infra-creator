# Introduction

We often need to deploy clusters in AWS to experiment something. This artifact contains terraform and shell script to provision servers required to run CP in 1 DC, 2 DC or 3 DC architecture. 

It creates:
* A number of EC2 instances to deploy Zookeeper, Kafka etc.
* 1 or 2 or 3 VPCs for multiple DC deployment
* VPC network peerings, subnets, route table rules and security groups.

## EC2
The EC2 instance will be created using the AMI specified in the `linux_ami_id` variable of the `terraform.tfvars` file.
You can also use a different AMI for a specific CP component.

```json
  {
    instance_type = "t3.micro"                //instance type
    name          = "sishuo-ansible",         
    dns_prefix    = "b1"                      //dns prefix used for this instance
    ip            = ["192.168.128.30"]
    ebs           = "50"
    ami           = "ami-xxxxx"   //Change AMI ID here
  }
```

# Usage

## Create Resources
Assume you have AWS access key and secrets configured properly on your laptop.

```
terraform init
terraform apply -var="MY_IP=$(curl -s ifconfig.me)" -auto-approve
```

## Teardown
```
terraform apply -destroy -var="MY_IP=$(curl -s ifconfig.me)"
```

## Accessing Servers

### DNS
The terraform creates both public DNS records and private DNS records.

For the public DNS:
It reuses the existing public DNS zone (`ps.confluent-internal.io`) in Route 53

For the internal DNS:
It creates a private zone using `{owner}.dev` format. e.g. `sishuo.dev`.

Then the scripts add DNS records for both public and private zone. See below sections.

### Firewall
All traffics to the servers are allowed from your own public IPs. If you don't like this you can modify the security group part of the terraform code in the `main.tf`.

### From Your Laptop
Add below lines to your `~/.ssh/config` file
```
Host z1
  HostName z1.sishuo.ps.confluent-internal.io
  User ec2-user
  IdentityFile /Users/yss/Desktop/sishuo-keypair-sg.pem

Host b1
  HostName b1.sishuo.ps.confluent-internal.io
  User ec2-user
  IdentityFile /Users/yss/Desktop/sishuo-keypair-sg.pem
```

Then you can access any server created:
```
ssh z1
```
Replace `z1` with `z2` for other Zookeeper instances or `b1` for broker 1.

This part is taken from the `terraform.tfvars` file -> components -> dns_prefix

### Within the VPC

Servers can talk to each other using private DNS.

A Route53 DNS zone is created using `{owner}.dev` naming convention.

All servers can be accessed using domain `{dns-prefix}.{owner}.dev`. 

E.g. `z1.sishuo.dev`

`b1.sishuo.dev`. 

This allows you to use meaningful names in the server properties file instead of IP addresses.

## Multi DC

Use the terraform script in the `multi-dc` folder. The command is the same.
* 3 VPC/DC created with peering and routing. Servers in each DC can communicate freely with each other.
* VPC 1: subnet 0 and subnet 1.
* VPC 2: subnet 2
* VPC 3: subnet 3
* Subnet 0 can be used for common infras such as AD server, Prometheus/Grafana etc.
* Subnet 1,2,3 for Zookeeper, brokers etc.
* You can define CIDR range in `tfvars` file.