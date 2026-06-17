#!/bin/bash

export AWS_PAGER=""
export AWS_DEFAULT_REGION="us-east-2"

INSTANCE_ID="i-0a2e2850e2d461ebf"
file_to_find="../server/.env.docker"

if [ ! -f "$file_to_find" ]; then
    echo "ERROR: File not found: $file_to_find"
    exit 1
fi

ipv4_address=$(aws ec2 describe-instances \
  --region "$AWS_DEFAULT_REGION" \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text \
  --no-cli-pager)

if [ -z "$ipv4_address" ] || [ "$ipv4_address" = "None" ]; then
    echo "ERROR: Could not retrieve IP address for instance $INSTANCE_ID"
    exit 1
fi

sed -i -e "s|FRONTEND_URL.*|FRONTEND_URL=\"http://${ipv4_address}:5173\"|g" "$file_to_find"

echo "Updated FRONTEND_URL in $file_to_find"