####
# Created by Anubhav Swami - subscribe to my youtube channel for more informatoin (youtube.com/anubhavswami)
# This terraform script has community support only, there is no offical support for this this terraform script.
# Linkedin - https://www.linkedin.com/in/anubhavswami/
####

####
# This terraform template deploys single instance of Cisco ASAv using aws marketplace image (BYOL offering). 
# Cisco ASA is deployed with 4 interfaces (mgmt, outside, inside and dmz) in a new VPC 
####

####
# Variables used in this terraform 
####
variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "key_name" {
  default = "ciscofw"
}
variable "region" {
        default = "us-east-1"
}

variable "ASA_version" {
    default = "asav9-15-1"
} 

variable "vpc_name" {
    default = "service-vpc"
}

####
# VPC cidr is /16 
####
variable "vpc_cidr" {
    default = "10.82.0.0/16"
}

####
# defining the subnets variables with the default value for Three Tier Architecure. 
####
variable "mgmt" {
    default = "10.82.0.0/24"
}
variable "outside" {
    default = "10.82.1.0/24"
}
variable "inside" {
    default = "10.82.2.0/24"
}
variable "dmz" {
    default = "10.82.3.0/24"
}

####
# assigning IP address of Cisco ASA 
####
variable "asa_mgmt_ip" {
    default = "10.82.0.10"
}
variable "asa_outside_ip" {
    default = "10.82.1.10"
}
variable "asa_inside_ip" {
    default = "10.82.2.10"
}
variable "asa_dmz_ip" {
    default = "10.82.3.10"
}

####
# assigning IP address of Cisco ASA 
####
variable "size" {
  default = "c5.xlarge"
}

####
# existing SSH Key on the AWS 
####
variable "availability_zone_count" {
  default = 1
}

variable "instances_per_az" {
  default = 1
}

####
# Cisco ASA marketplace image and version selection
####
data "aws_ami" "asav" {
  #most_recent = true      // you can enable this if you want to deploy more
  owners      = ["aws-marketplace"]

 filter {
    name   = "name"
    values = ["${var.ASA_version}*"]
  }

  filter {
    name   = "product-code"
    values = ["663uv4erlxz65quhgaz9cida0"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "template_file" "startup_file" {
  template = file("asa-day0-configuration-file.txt") // this file contains day0 configuration file for Cisco ASA
}

data "aws_availability_zones" "available" {}

####
# Provider (access_key and secret_key to AWS account)
####
provider "aws" {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    region     = var.region
}

####
# VPC resources 
####
resource "aws_vpc" "asa_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_classiclink   = false
  instance_tenancy     = "default"
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "mgmt" {
  count = var.availability_zone_count
  vpc_id            = aws_vpc.asa_vpc.id
  cidr_block        = var.mgmt
  availability_zone = data.aws_availability_zones.available.names[count.index]

 tags = {
    Name = "mgmt"
  }
}

resource "aws_subnet" "outside" {
  count = var.availability_zone_count
  vpc_id            = aws_vpc.asa_vpc.id
  cidr_block        = var.outside
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "outside"
  }
}

resource "aws_subnet" "inside" {
  count = var.availability_zone_count
  vpc_id            = aws_vpc.asa_vpc.id
  cidr_block        = var.inside
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "inside"
  }
}

resource "aws_subnet" "dmz" {
  count = var.availability_zone_count
  vpc_id            = aws_vpc.asa_vpc.id
  cidr_block        = var.dmz
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "dmz"
  }
}

####
# VPC resources (this security group allows everything - recommendation is to control traffic from Cisco firewall)
####
resource "aws_security_group" "allow_all" {
  name        = "allow-all"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.asa_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-all"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id      = aws_vpc.asa_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "allow-local"
  }
}

####
# Network Interfaces, ASA instance, attaching the SG to interfaces
####
resource "aws_network_interface" "asa_mgmt" {
  description   = "asa-mgmt"
  count = var.availability_zone_count * var.instances_per_az
  subnet_id     = aws_subnet.mgmt[floor(count.index / var.instances_per_az)].id
  private_ips   = [var.asa_mgmt_ip]
  source_dest_check = false
}

resource "aws_network_interface" "asa_outside" {
  description = "asa-outside"
  count = var.availability_zone_count * var.instances_per_az
  subnet_id   = aws_subnet.outside[floor(count.index / var.instances_per_az)].id
  private_ips = [var.asa_outside_ip]
  source_dest_check = false
}

resource "aws_network_interface" "asa_inside" {
  description = "asa-inside"
  count = var.availability_zone_count * var.instances_per_az
  subnet_id   = aws_subnet.inside[floor(count.index / var.instances_per_az)].id
  private_ips = [var.asa_inside_ip]
  source_dest_check = false
}

resource "aws_network_interface" "asa_dmz" {
  description = "asd-dmz"
  count = var.availability_zone_count * var.instances_per_az
  subnet_id   = aws_subnet.dmz[floor(count.index / var.instances_per_az)].id
  private_ips = [var.asa_dmz_ip]
  source_dest_check = false
}

resource "aws_network_interface_sg_attachment" "asa_mgmt_attachment" {
  count = var.availability_zone_count * var.instances_per_az
  depends_on           = [aws_network_interface.asa_mgmt]
  security_group_id    = aws_security_group.allow_all.id
  network_interface_id = aws_network_interface.asa_mgmt[count.index].id
}

resource "aws_network_interface_sg_attachment" "asa_outside_attachment" {
  count = var.availability_zone_count * var.instances_per_az
  depends_on           = [aws_network_interface.asa_outside]
  security_group_id    = aws_security_group.allow_all.id
  network_interface_id = aws_network_interface.asa_outside[count.index].id
}

resource "aws_network_interface_sg_attachment" "asa_inside_attachment" {
  count = var.availability_zone_count * var.instances_per_az
  depends_on           = [aws_network_interface.asa_inside]
  security_group_id    = aws_security_group.allow_all.id
  network_interface_id = aws_network_interface.asa_inside[count.index].id
}

resource "aws_network_interface_sg_attachment" "asa_dmz_attachment" {
  count = var.availability_zone_count * var.instances_per_az
  depends_on           = [aws_network_interface.asa_dmz]
  security_group_id    = aws_security_group.allow_all.id
  network_interface_id = aws_network_interface.asa_dmz[count.index].id
}

####
# Internet Gateway (IGW) and route tables (RT)
####

####
# define the internet gateway (IGW)
####
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.asa_vpc.id
  tags = {
    Name = "igw"
  }
}

####
# create the route table for mgmt, outside, inside and dmz
####
resource "aws_route_table" "mgmt-rt" {
  vpc_id = aws_vpc.asa_vpc.id
  tags = {
    Name = "mgmt-rt"
  }
}

resource "aws_route_table" "outside-rt" {
  vpc_id = aws_vpc.asa_vpc.id
  tags = {
    Name = "outside-rt"
  }
}

resource "aws_route_table" "inside-rt" {
  vpc_id = aws_vpc.asa_vpc.id
  tags = {
    Name = "inside-rt"
  }
}

resource "aws_route_table" "dmz-rt" {
  vpc_id = aws_vpc.asa_vpc.id
  tags = {
    Name = "dmz-rt"
  }
}

####
# To define the default routes via IGW
####
resource "aws_route" "mgmt_default_route" {
  route_table_id         = aws_route_table.mgmt-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

####
# To define the default route for outside subnet via IGW
####
resource "aws_route" "outside_default_route" {
  route_table_id          = aws_route_table.outside-rt.id
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = aws_internet_gateway.igw.id
}

####
# To define the default route for inside subnet via ASAv inside interface 
####
resource "aws_route" "inside_default_route" {
  count = var.availability_zone_count * var.instances_per_az
  depends_on              = [aws_instance.asav]
  route_table_id          = aws_route_table.inside-rt.id
  destination_cidr_block  = "0.0.0.0/0"
  network_interface_id    = aws_network_interface.asa_inside[count.index].id
}

####
# To define the default route for DMZ subnet via ASAv dmz interface 
####
resource "aws_route" "DMZ_default_route" {
  count = var.availability_zone_count * var.instances_per_az
  depends_on              = [aws_instance.asav]  
  route_table_id          = aws_route_table.dmz-rt.id
  destination_cidr_block  = "0.0.0.0/0"
  network_interface_id    = aws_network_interface.asa_dmz[count.index].id
}

####
# assocate mgmt-rt to mgmt subnet 
####
resource "aws_route_table_association" "mgmt_association" {
  count = var.availability_zone_count * var.instances_per_az
  subnet_id      = aws_subnet.mgmt[count.index].id
  route_table_id = aws_route_table.mgmt-rt.id
}

####
# associate outsid-rt to outside subnet 
####
resource "aws_route_table_association" "outside_association" {
  count = var.availability_zone_count * var.instances_per_az
  subnet_id      = aws_subnet.outside[count.index].id
  route_table_id = aws_route_table.outside-rt.id
}

####
# assocate inside-rt to inside subnet 
####
resource "aws_route_table_association" "inside_association" {
  count = var.availability_zone_count * var.instances_per_az
  subnet_id      = aws_subnet.inside[count.index].id
  route_table_id = aws_route_table.inside-rt.id
}

####
# assocate dmz-rt to dmz subnet 
####
resource "aws_route_table_association" "dmz_association" {
  count = var.availability_zone_count * var.instances_per_az
  subnet_id      = aws_subnet.dmz[count.index].id
  route_table_id = aws_route_table.dmz-rt.id
}

#####
# AWS External IP address creation and associating it to the mgmt and outside interface.
# Cisco ASA would have two EIPs assigned - one to management interface (management-only) and second to outsid interface. 
#####
resource "aws_eip" "asa_mgmt-EIP" {
  count = var.availability_zone_count * var.instances_per_az
  vpc   = true
  depends_on = [aws_internet_gateway.igw]
  tags = {
    "Name" = "asa-managment-ip"
  }
}

resource "aws_eip" "asa_outside-EIP" {
  count = var.availability_zone_count * var.instances_per_az
  vpc   = true
  depends_on = [aws_internet_gateway.igw]
  tags = {
    "Name" = "asa-outside-ip"
  }
}

resource "aws_eip_association" "asa-mgmt-ip-assocation" {
  count = var.availability_zone_count * var.instances_per_az
  network_interface_id = aws_network_interface.asa_mgmt[count.index].id
  allocation_id        = aws_eip.asa_mgmt-EIP[count.index].id
}
resource "aws_eip_association" "asa-outside-ip-association" {
  count = var.availability_zone_count * var.instances_per_az
  network_interface_id = aws_network_interface.asa_outside[count.index].id
  allocation_id        = aws_eip.asa_outside-EIP[count.index].id
}

#####
# Create the Cisco ASA Instance with four interfaces (mgmt, outside, inside and dmz). 
# Cisco ASA would have two EIPs assigned - one to management interface (management-only) and second to outsid interface. 
#####
resource "aws_instance" "asav" {
   count = var.availability_zone_count * var.instances_per_az
    ami                 = data.aws_ami.asav.id
    instance_type       = var.size 
    key_name            = var.key_name
    
network_interface {
    network_interface_id = aws_network_interface.asa_mgmt[count.index].id
    device_index         = 0
  }

   network_interface {
    network_interface_id = aws_network_interface.asa_outside[count.index].id
    device_index         = 1
  }

    network_interface {
    network_interface_id = aws_network_interface.asa_inside[count.index].id
    device_index         = 2
  }

    network_interface {
    network_interface_id = aws_network_interface.asa_dmz[count.index].id
    device_index         = 3
  }
  
  user_data = data.template_file.startup_file.rendered

  tags = {
    Name = "cisco-asa"
  }
}

####
# Output - This session displays public IP address of cisco-asa deployed by this terraform script 
####
output "ip" {
  value = aws_eip.asa_mgmt-EIP.*.public_ip
}

####
# End of the terraform script!  
####