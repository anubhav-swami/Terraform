####
# AWS Environment -- Remove the # to before configure a value to it. 
# If you dont provide any value, it will take the default value 
####

####
# AWS Creditials to access the AWS Cloud
####
aws_access_key      = ""

aws_secret_key      = ""

####
# Define new VPC name and specify region
####
vpc_name            = "service-vpc"
region               = "us-east-2"


####
# Define CIDR, subnets (mgmt, outside, inside, and dmz)
####

vpc_cidr    = "10.82.0.0/16"
mgmt        = "10.82.0.0/24"
outside     = "10.82.1.0/24"
inside      = "10.82.2.0/24"
dmz         = "10.82.3.0/24" 
key_name    = "ciscofw"  

####
# Generate the key if you want to login thru the key
####

####
# define the Instance size of ASA and attach the interfaces and Day0 Configuration
####

####
# ASA Interfaces IP address Configurations 
# Download the ASA_startup_file and manage the Configurations 
# Please refer ASAv datasheet for the supported "size" 
# https://www.cisco.com/c/en/us/products/collateral/security/adaptive-security-virtual-appliance-asav/datasheet-c78-733399.html?dtid=osscdc000283
#Remove the # before using it
####

size                = "c5.xlarge"
ASA_version         = "asav9-15-1-1"

####
# Allowed Values = asav9-15-1, asav9-14-1-30, asav9-12-4-4, asav9-14-1-10, asav9-13-1-12
####

asa_mgmt_ip       =     "10.82.0.10"
asa_outside_ip    =     "10.82.1.10"  
asa_inside_ip     =     "10.82.2.10"       
asa_dmz_ip        =     "10.82.3.10"