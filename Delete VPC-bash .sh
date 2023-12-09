#!/bin/bash

AWS_REGION="us-east-1"

# Get a list of running EC2 instances without a specific tag
#instance_ids=$(aws ec2 describe-instances \
 # --filters "Name=instance-state-name,Values=running" \
  #--query "Reservations[].Instances[?Tags[?Key!='$TAG_KEY']].InstanceId" \
  #--output text)

# Check if there are any instances without the specified tag
#if [ -z "$instance_ids" ]; then
 #   echo "No running instances without the specified tag found."
#else
 #   # Loop through each instance without the specified tag and terminate it
  #  for instance_id in $instance_ids; do
   #     echo "Terminating instance without the specified tag: $instance_id"
    #    aws ec2 terminate-instances --instance-ids $instance_id
    #done
	
# Get a list of all VPC IDs
all_vpcs=$(aws ec2 describe-vpcs --region $AWS_REGION --query "Vpcs[?not Tags]" --output text --query 'Vpcs[*].VpcId')

if [ -z "$all_vpcs" ]; then
  echo "No non-tagged VPCs found."
  exit 0
fi

for vpc_id in $all_vpcs; do
  echo "Deleting VPC: $vpc_id"

  # Delete subnets associated with the VPC
  subnet_ids=$(aws ec2 describe-subnets --region $AWS_REGION --filters Name=vpc-id,Values=$vpc_id --query 'Subnets[*].SubnetId' --output text)
  for subnet_id in $subnet_ids; do
    aws ec2 delete-subnet --region $AWS_REGION --subnet-id $subnet_id
    echo "Deleted Subnet: $subnet_id"
  done

  # Delete internet gateways attached to the VPC
  igw_id=$(aws ec2 describe-internet-gateways --region $AWS_REGION --filters Name=attachment.vpc-id,Values=$vpc_id --query 'InternetGateways[*].InternetGatewayId' --output text)
  if [ -n "$igw_id" ]; then
    aws ec2 detach-internet-gateway --region $AWS_REGION --internet-gateway-id $igw_id --vpc-id $vpc_id
    aws ec2 delete-internet-gateway --region $AWS_REGION --internet-gateway-id $igw_id
    echo "Deleted Internet Gateway: $igw_id"
  fi

  # Delete route tables associated with the VPC
  rtb_ids=$(aws ec2 describe-route-tables --region $AWS_REGION --filters Name=vpc-id,Values=$vpc_id --query 'RouteTables[*].RouteTableId' --output text)
  for rtb_id in $rtb_ids; do
    aws ec2 delete-route-table --region $AWS_REGION --route-table-id $rtb_id
    echo "Deleted Route Table: $rtb_id"
  done

  # Finally, delete the VPC
  aws ec2 delete-vpc --region $AWS_REGION --vpc-id $vpc_id
  echo "Deleted VPC: $vpc_id"
done

