#!/bin/bash

export AWS_PAGER=""
export AWS_DEFAULT_REGION=ap-south-1

# Set the Instance ID and path to the .env file
INSTANCE_ID="i-0b953e207c68926fb"

# Path to the .env file
file_to_find="../server/.env.docker"

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

# Check the current FRONTEND_URL in the .env file
current_url=$(sed -n "4p" "$file_to_find")

# Update the .env file if the IP address has changed
if [[ "$current_url" != "FRONTEND_URL=\"http://${ipv4_address}:5173\"" ]]; then
    sed -i -e "s|FRONTEND_URL.*|FRONTEND_URL=\"http://${ipv4_address}:5173\"|g" "$file_to_find"
    echo "Updated FRONTEND_URL in $file_to_find"
else
    echo "FRONTEND_URL is already up to date"
fi
