#!/bin/bash

export AWS_PAGER=""
export AWS_DEFAULT_REGION="us-east-2"

INSTANCE_ID="i-056e0e1b253efec27"
file_to_find="../client/.env.docker"

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

sed -i -e "s|REACT_APP_API_URL.*|REACT_APP_API_URL=\"http://${ipv4_address}:31100\"|g" "$file_to_find"

echo "Updated REACT_APP_API_URL in $file_to_find"