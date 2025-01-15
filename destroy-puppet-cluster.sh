#!/bin/bash

# Variables
AWS_REGION="us-east-1"
SECURITY_GROUP_NAME="puppet-cluster-sg"
PEM_KEY_NAME="puppet-controller-key"
CONTROLLER_NAME="puppet-controller"
WORKER1_NAME="worker-node-amazon-linux"
WORKER2_NAME="worker-node-ubuntu"

# Function to get instance IDs by Name tag
get_instance_ids_by_name() {
  local name=$1
  aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$name" "Name=instance-state-name,Values=running" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --region $AWS_REGION \
    --output text
}

# Function to get Security Group ID
get_security_group_id() {
  local group_name=$1
  aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=$group_name" \
    --query "SecurityGroups[*].GroupId" \
    --region $AWS_REGION \
    --output text
}

# Terminate Instances
echo "Terminating Puppet cluster instances..."
CONTROLLER_INSTANCE_ID=$(get_instance_ids_by_name $CONTROLLER_NAME)
WORKER1_INSTANCE_ID=$(get_instance_ids_by_name $WORKER1_NAME)
WORKER2_INSTANCE_ID=$(get_instance_ids_by_name $WORKER2_NAME)

if [ -n "$CONTROLLER_INSTANCE_ID" ] || [ -n "$WORKER1_INSTANCE_ID" ] || [ -n "$WORKER2_INSTANCE_ID" ]; then
  aws ec2 terminate-instances \
    --instance-ids $CONTROLLER_INSTANCE_ID $WORKER1_INSTANCE_ID $WORKER2_INSTANCE_ID \
    --region $AWS_REGION
  echo "Instances termination initiated."
else
  echo "No running instances found."
fi

# Delete Security Group
echo "Deleting Security Group..."
SECURITY_GROUP_ID=$(get_security_group_id $SECURITY_GROUP_NAME)
if [ -n "$SECURITY_GROUP_ID" ]; then
  aws ec2 delete-security-group --group-id $SECURITY_GROUP_ID --region $AWS_REGION
  echo "Security Group deleted."
fi

# Delete PEM Key Pair
echo "Deleting PEM Key Pair..."
aws ec2 delete-key-pair --key-name $PEM_KEY_NAME --region $AWS_REGION
