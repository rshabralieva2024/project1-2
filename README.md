# project1-2
# Terraform Module: Three-Tier Application on AWS


This Terraform module sets up a three-tier application on AWS, including VPC, subnets, NAT gateways, security groups, launch configurations, auto-scaling groups, load balancers, and Route 53 configurations.

## Features

- **VPC**: Creates a new Virtual Private Cloud (VPC) with a specified CIDR block.
- **Subnets**: Sets up public and private subnets across multiple availability zones.
- **Internet Gateway**: Attaches an Internet Gateway to the VPC for internet access.
- **NAT Gateways**: Creates NAT Gateways for outbound internet access from private subnets.
- **Route Tables**: Configures route tables for public and private subnets.
- **Security Groups**: Defines security groups for the web application.
- **Launch Configuration**: Configures EC2 instances for the web application using a specified AMI.
- **Auto Scaling Group**: Sets up an Auto Scaling Group (ASG) to manage EC2 instances.
- **Application Load Balancer (ALB)**: Sets up an ALB for load balancing the web application.
- **Route 53**: Configures Route 53 for DNS management.


## Usage

```hcl
module "three_tier_app" {
  source = "./path-to-your-module"

  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  db_username        = "your_db_username"
  db_password        = "your_db_password"
  key_name           = "your_ssh_key_name"
}

Requirements
Name	Version
terraform	>= 0.12.0
aws	>= 3.0
Providers
Name	Version
aws	>= 3.0
Inputs
Name	Description	Type	Default	Required
availability_zones	List of availability zones to deploy	list(string)	["us-east-2a", "us-east-2b", "us-east-2c"]	no
db_username	Database username	string	n/a	yes
db_password	Database password	string	n/a	yes
key_name	SSH key name for EC2 instances	string	n/a	yes
Outputs
Name	Description
vpc_id	The ID of the VPC
public_subnet_ids	The IDs of the public subnets
private_subnet_ids	The IDs of the private subnets
web_sg_id	The ID of the web security group
alb_dns_name	The DNS name of the ALB
Resources
VPC
aws_vpc.main
Subnets
aws_subnet.public
aws_subnet.private
Internet Gateway
aws_internet_gateway.igw
NAT Gateways
aws_nat_gateway.nat
aws_eip.nat
Route Tables
aws_route_table.public
aws_route_table.private
aws_route_table_association.public
aws_route_table_association.private
Security Groups
aws_security_group.web_sg
Launch Configuration
aws_launch_configuration.wordpress
Auto Scaling Group
aws_autoscaling_group.wordpress_asg
Load Balancer
aws_lb.wordpress
aws_lb_target_group.wordpress
aws_lb_listener.wordpress
Route 53
aws_route53_zone.example
aws_route53_record.wordpress

Requirements
Name	       Version
terraform	>= 0.12.0
aws	      >= 3.0

Providers
Name	   Version
aws   >= 3.0

Inputs
Name	                   Description	        Type	                   Default	                   Required
availability_zones	List of AZ to deploy	list(string)	["us-east-2a", "us-east-2b", "us-east-2c"]	no
db_username	        Database username	         string	                       n/a	                  yes
db_password	        Database password	         string	                       n/a	                  yes
key_name	          SSH key name for EC2     	string	                       n/a	                  yes  

Outputs
Name	                      Description
vpc_id	                  The ID of the VPC
public_subnet_ids	        The IDs of the public subnets
private_subnet_ids	      The IDs of the private subnets
web_sg_id	                The ID of the web security group
alb_dns_name	            The DNS name of the ALB

Resources
VPC
aws_vpc.main
Subnets
aws_subnet.public
aws_subnet.private
Internet Gateway
aws_internet_gateway.igw
NAT Gateways
aws_nat_gateway.nat
aws_eip.nat
Route Tables
aws_route_table.public
aws_route_table.private
aws_route_table_association.public
aws_route_table_association.private
Security Groups
aws_security_group.web_sg
Launch Configuration
aws_launch_configuration.wordpress
Auto Scaling Group
aws_autoscaling_group.wordpress_asg
Load Balancer
aws_lb.wordpress
aws_lb_target_group.wordpress
aws_lb_listener.wordpress
Route 53
aws_route53_zone.example
aws_route53_record.wordpress


