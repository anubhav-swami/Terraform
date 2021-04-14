Deploy Cisco ASAv single instances using AWS marketplace image. This Terraform script deploys Cisco ASAv with four interfaces (mgmt, outside, inside and dmz). 

**Prerequisite**
•	Terraform
•	aws v3.27.0 (signed by HashiCorp)
•	aws hashicorp/template v2.2.0

Overview

Using this Terraform template, a single instance ASA can be deployed in a new VPC with the following components,

•	New VPC with four subnets (mgmt, outside, inside, and dmz) in a single AZ
•	Internet Gateway (IGW) to provide internet connectivity
•	Route table and their attachment to subnets. 
•	Two security groups (default and allow all) – If you need visibility on Cisco Firewall, then you need to allow everything in AWS and control traffic using Cisco Firewall. 
•	EIP attachment to the Management and Outside subnet.

The following parameters should be configured in the "terraform.tfvars" file before using the templates. Please note the value provided below is just for example. Please change it based on your requirements.

Parameters

•	Specify your access key and secret key credentials to access the AWS Cloud
  - aws_access_key = ""
  - aws_secret_key = ""

•	Define wew VPC in a specific Region and Availability Zone
  - vpc_name = "service-vpc"
  - region = "us-east-1"

•	Define CIDR, Subnets for managment and three for Inside, Outisde and DMZ
  - vpc_cidr = "10.82.0.0/16"
  -	mgmt_subnet = "10.82.0.0/24"
  -	outside_subnet = "10.82.1.0/24"
  - inside_subnet = "10.82.2.0/24"
  - dmz_subnet = "10.82.3.0/24"

•	Define key_name = "" --> .pem key file should be generated before running terraform script

•	Define the Instance size of ASA and attach the interfaces and day0 configuration
  - ASA Interfaces IP address configurations download the ASA_startup_file and update the configurations

•	Please refer the below ASAv datasheet for the supported "size" https://www.cisco.com/c/en/us/products/collateral/security/adaptive-security-virtual-appliance-asav/datasheet-c78-733399.html?dtid=osscdc000283

•	The following parameters are using in this example:
•	size = "c5.xlarge"
•	ASA_version = "asav9-15-1-1" 

Note: llowed Values = asav9-15-1, asav9-14-1-30, asav9-12-4-4, asav9-14-1-10, asav9-13-1-12

•	asa_mgmt_ip = "10.82.0.10"
•	asa_outside_ip = "10.82.1.10"
•	asa_inside_ip = "10.82.2.10"
•	asa_dmz_ip = "10.82.3.10"

Deployment Procedure

•	Clone or Download the Repository
•	Customize the variables in the terraform.tfvars and variables.tf (only to change the default value)
•	Initialize the providers and modules
•	go to the specific terraform folder from the cli $ cd xxxx $ terraform init
•	submit the terraform plan $ terraform plan -out
•	verify the output of the plan in the terminal, if everything is fine then apply the plan $ terraform apply
•	if output is fine, configure it by typing "yes"
•	Once if exected, it will show you the ip addresss of the managment interface configured. use this to access the ASA
•	To Destroy the setup and ASAv instance created thru terraform.
•	To destroy the instance, use the command: $ terraform destroy

Note: Please don't delete or modify the file with the extension ".tfstate" file. This file maintained the current deployment status and used while modifying any parameters or while destroying this setup.
