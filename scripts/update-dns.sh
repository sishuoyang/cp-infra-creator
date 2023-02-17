#!/bin/bash

HOSTED_ZONE_ID="Z267DABJTL4JFI"

# Get the instance information as a JSON array using instance name prefix <<== Remember to change
instances=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=sishuo*" \
  --query "Reservations[].Instances[].{InstanceName:Tags[?Key=='Name'] | [0].Value, PublicIP:PublicIpAddress}" \
  --output json)

# Loop through the instances
for instance in $(echo "${instances}" | jq -r '.[] | @base64'); do
  # Decode the base64 encoded string
  instance_info=$(echo "${instance}" | base64 --decode)

  # Extract the instance name and public IP
  instance_name=$(echo "${instance_info}" | jq -r '.InstanceName')
  public_ip=$(echo "${instance_info}" | jq -r '.PublicIP')


  # Check if the public IP address is not null or empty
  if [[ "$public_ip" != "null" ]]; then
    # Update the Route 53 DNS record in the hosted zone
    # Remove the "sishuo-" prefix from the instance name
    instance_name=${instance_name#sishuo-}
    echo "instance name:${instance_name}, ip: ${public_ip}"
    aws route53 change-resource-record-sets \
      --hosted-zone-id ${HOSTED_ZONE_ID} \
      --change-batch '{
        "Changes": [
          {
            "Action": "UPSERT",
            "ResourceRecordSet": {
              "Name": "'"$instance_name"'.sishuo.ps.confluent-internal.io",
              "Type": "A",
              "TTL": 60,
              "ResourceRecords": [
                {
                  "Value": "'"$public_ip"'"
                }
              ]
            }
          }
        ]
      }' > /dev/null
  fi

done
