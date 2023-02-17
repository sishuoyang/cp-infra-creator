#!/bin/bash

# todo: routing table need to be bidirectional, fixed. verify.
# 3DC security group

# Query for all VPCs with the "sishuo-" prefix
vpcs=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=sishuo-*" --query 'Vpcs[*].VpcId' --output text)
JUMP_VPC_ID="vpc-8ebf34e9"
JUMP_RT_ID="rtb-c49298a3"
# Iterate through the VPCs and create a VPC peering connection to vpc-8ebf34e9
for vpc in $vpcs; do
    echo "Checking VPC peering connection for VPC $vpc"

    # Check if a peering connection already exists
    existing_peer=$(aws ec2 describe-vpc-peering-connections \
        --filters "Name=requester-vpc-info.vpc-id,Values=$vpc" \
                  "Name=accepter-vpc-info.vpc-id,Values=$JUMP_VPC_ID" \
                  "Name=status-code,Values=active" \
        --query 'VpcPeeringConnections[0].VpcPeeringConnectionId' \
        --output text)
    echo "existing_peer=$existing_peer"
    # Create a new peering connection if one does not exist
    if [[ -z $existing_peer ]]; then
        echo "Create new peering connection for $vpc and $JUMP_VPC_ID"
        peer=$(aws ec2 create-vpc-peering-connection --vpc-id $vpc --peer-vpc-id $JUMP_VPC_ID --peer-region ap-southeast-1 --query 'VpcPeeringConnection.VpcPeeringConnectionId' --output text)

        # Accept the VPC peering connection
        aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $peer

    else
        echo "Using existing VPC peering connection $existing_peer"
        peer=$existing_peer
    fi

    vpc_cidr=$(aws ec2 describe-vpcs --vpc-ids $vpc --query 'Vpcs[0].CidrBlock' --output text)

    #Create a route in the jump server subnet to the VPC subnet via the peering connection.
    aws ec2 create-route --route-table-id $JUMP_RT_ID --destination-cidr-block $vpc_cidr --vpc-peering-connection-id $peer
    

    # Query subnet with prefix "sishuo-" in the $vpc
    subnets=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc" "Name=tag:Name,Values=sishuo-*" --query 'Subnets[*].SubnetId' --output text)
    
    # Get the jump server VPC CIDR
    jump_vpc_cidr=$(aws ec2 describe-vpcs --vpc-ids $JUMP_VPC_ID --query 'Vpcs[0].CidrBlock' --output text)

    for subnet in $subnets; do
        # create route in the VPC subnet to the jump server subnet via the VPC peering
        aws ec2 create-route --route-table-id $subnet --destination-cidr-block $jump_vpc_cidr --vpc-peering-connection-id $peer
    done

done
