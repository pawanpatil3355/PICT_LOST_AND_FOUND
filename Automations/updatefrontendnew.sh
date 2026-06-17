#!/bin/bash

export AWS_PAGER=""
export AWS_DEFAULT_REGION=ap-south-1

# Set the Instance ID and path to the .env file
INSTANCE_ID="i-056e0e1b253efec27"

# Path to the .env file
file_to_find="../client/.env.docker"

# Check if file exists before processing
if [ ! -f "$file_to_find" ]; then
    echo "ERROR: File not found: $file_to_find"
    exit 1
fi

# Retrieve the public IP address of the specified EC2 instance
ipv4_address=$(aws ec2 describe-instances \
  --region "$AWS_DEFAULT_REGION" \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text \
  --no-cli-pager)

if [ -z "$ipv4_address" ]; then
    echo "ERROR: Could not retrieve IP address for instance $INSTANCE_ID"
    exit 1
fi

# Check the current REACT_APP_API_URL in the .env file
current_url=$(cat "$file_to_find")

# Update the .env file if the IP address has changed
if [[ "$current_url" != "REACT_APP_API_URL=\"http://${ipv4_address}:31100\"" ]]; then
    sed -i -e "s|REACT_APP_API_URL.*|REACT_APP_API_URL=\"http://${ipv4_address}:31100\"|g" "$file_to_find"
    echo "Updated REACT_APP_API_URL in $file_to_find"
else
    echo "REACT_APP_API_URL is already up to date"
fi

