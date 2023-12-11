#!/bin/bash

# Set your AWS region
AWS_REGION="us-east-1"

# Create VPC
echo "Creating VPC..."
vpc_id=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --region $AWS_REGION --output json | jq -r '.Vpc.VpcId')

# Create internet gateway
echo "Creating Internet Gateway..."
igw_id=$(aws ec2 create-internet-gateway --region $AWS_REGION --output json | jq -r '.InternetGateway.InternetGatewayId')

# Attach internet gateway to VPC
aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id --region $AWS_REGION

# Create a subnet
echo "Creating Subnet..."
subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.0.0/24 --region $AWS_REGION --output json | jq -r '.Subnet.SubnetId')

# Create a route table
echo "Creating Route Table..."
rtb_id=$(aws ec2 create-route-table --vpc-id $vpc_id --region $AWS_REGION --output json | jq -r '.RouteTable.RouteTableId')

# Associate the route table with the subnet
aws ec2 associate-route-table --subnet-id $subnet_id --route-table-id $rtb_id --region $AWS_REGION

# Create a route to the internet through the internet gateway
aws ec2 create-route --route-table-id $rtb_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id --region $AWS_REGION

# Launch EC2 instance
echo "Launching EC2 instance..."

aws ec2 describe-key-pairs --region $AWS_REGION
#$KeyName= "narek-es2-2-key"

#aws ec2 run-instances \
  --image-id ami-0fc5d935ebf8bc3bc  \
  --instance-type t2.micro \
  --key-name $KeyName \
  --subnet-id $subnet_id \
  --region $AWS_REGION

echo "Script execution completed!"

# Output created resource IDs
echo "VPC created with ID: $vpc_id"
echo "Internet Gateway created with ID: $igw_id"
echo "Subnet created with ID: $subnet_id"
echo "Route Table created with ID: $rtb_id"