#!/bin/bash

# Variables
AWS_REGION="us-east-1"
SECURITY_GROUP_NAME="puppet-cluster-sg"
PEM_KEY_NAME="puppet-controller-key"
CONTROLLER_NAME="puppet-server"
WORKER1_NAME="puppet-agent-amazon"
WORKER2_NAME="puppet-agent-ubuntu"
CONTROLLER_AMI="ami-0e2c8caa4b6378d8c" # Ubuntu AMI
WORKER1_AMI="ami-01816d07b1128cd2d"   # Amazon Linux AMI
WORKER2_AMI="ami-0e2c8caa4b6378d8c"   # Ubuntu AMI
CONTROLLER_INSTANCE_TYPE="t2.large"   # Larger instance for Controller
WORKER_INSTANCE_TYPE="t2.micro"       # Worker instance type
SCRIPT_DIR="$(dirname "$0")"
KEY_SAVE_PATH="$SCRIPT_DIR/${PEM_KEY_NAME}.pem"

# Step 1: Create Security Group
echo "Creating Security Group..."
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
  --group-name $SECURITY_GROUP_NAME \
  --description "Security group for Puppet cluster" \
  --region $AWS_REGION \
  --query "GroupId" --output text)

if [ -z "$SECURITY_GROUP_ID" ]; then
  echo "Failed to create Security Group. Exiting."
  exit 1
fi

echo "Security Group ID: $SECURITY_GROUP_ID"

# Add rules to Security Group: SSH, HTTP and Puppet
echo "Adding rules to Security Group..."
aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP_ID \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 \
  --region $AWS_REGION

aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --region $AWS_REGION

aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP_ID \
  --protocol tcp \
  --port 8140 \
  --cidr 0.0.0.0/0 \
  --region $AWS_REGION

# Step 2: Create PEM Key Pair
echo "Creating PEM Key Pair..."
if [ -f "$KEY_SAVE_PATH" ]; then
  echo "Key file already exists. Removing it."
  rm -f "$KEY_SAVE_PATH"
fi

aws ec2 create-key-pair \
  --key-name $PEM_KEY_NAME \
  --query "KeyMaterial" \
  --output text > "$KEY_SAVE_PATH"

if [ ! -f "$KEY_SAVE_PATH" ]; then
  echo "Failed to create PEM Key Pair. Exiting."
  exit 1
fi

chmod 400 "$KEY_SAVE_PATH"
echo "PEM Key Pair created and saved as $KEY_SAVE_PATH"

# Step 3: Launch Controller Node
echo "Launching Controller Node..."
CONTROLLER_INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $CONTROLLER_AMI \
  --count 1 \
  --instance-type $CONTROLLER_INSTANCE_TYPE \
  --key-name $PEM_KEY_NAME \
  --security-group-ids $SECURITY_GROUP_ID \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$CONTROLLER_NAME}]" \
  --region $AWS_REGION \
  --query "Instances[0].InstanceId" --output text)

if [ -z "$CONTROLLER_INSTANCE_ID" ]; then
  echo "Failed to launch Controller Node. Exiting."
  exit 1
fi

echo "Controller Node Instance ID: $CONTROLLER_INSTANCE_ID"

# Step 4: Launch Worker Nodes
echo "Launching Worker Node 1 (Amazon Linux)..."
WORKER1_INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $WORKER1_AMI \
  --count 1 \
  --instance-type $WORKER_INSTANCE_TYPE \
  --key-name $PEM_KEY_NAME \
  --security-group-ids $SECURITY_GROUP_ID \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$WORKER1_NAME}]" \
  --region $AWS_REGION \
  --query "Instances[0].InstanceId" --output text)

if [ -z "$WORKER1_INSTANCE_ID" ]; then
  echo "Failed to launch Worker Node 1. Exiting."
  exit 1
fi

echo "Worker Node 1 Instance ID: $WORKER1_INSTANCE_ID"

echo "Launching Worker Node 2 (Ubuntu)..."
WORKER2_INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $WORKER2_AMI \
  --count 1 \
  --instance-type $WORKER_INSTANCE_TYPE \
  --key-name $PEM_KEY_NAME \
  --security-group-ids $SECURITY_GROUP_ID \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$WORKER2_NAME}]" \
  --region $AWS_REGION \
  --query "Instances[0].InstanceId" --output text)

if [ -z "$WORKER2_INSTANCE_ID" ]; then
  echo "Failed to launch Worker Node 2. Exiting."
  exit 1
fi

echo "Worker Node 2 Instance ID: $WORKER2_INSTANCE_ID"

# Step 5: Display Public IP Addresses
echo "Fetching Public IP Addresses..."
INSTANCE_PUBLIC_IPS=$(aws ec2 describe-instances \
  --instance-ids $CONTROLLER_INSTANCE_ID $WORKER1_INSTANCE_ID $WORKER2_INSTANCE_ID \
  --query "Reservations[*].Instances[*].[Tags[?Key=='Name'].Value,PublicIpAddress]" \
  --output table)

echo "$INSTANCE_PUBLIC_IPS"

echo "Puppet cluster setup is complete!"
