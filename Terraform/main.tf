## Defines provider
provider "aws" {
    region = "us-east-1"
    shared_credentials_file = "/Users/Piche/DevOps2022/.aws/credentials"
}


## Defines VPC
resource "aws_vpc" "vpc_cicd" {
    cidr_block = "172.16.0.0/24"
    tags = {
        Name = "CI-CD-VPC"
    }
}


## Defines Subnets
### Public Subnet
resource "aws_subnet" "CICD_PublicSubnet" {
    vpc_id = aws_vpc.vpc_cicd
    cidr_block = "172.16.0.0/25"

    tags = {
        Name = "PublicSubnetCICD"
    }
}


### Private Subnet
resource "aws_subnet" "CICD_PrivateSubnet" {
    vpc_id = aws_vpc.vpc_cicd
    cidr_block = "172.16.0.128/25"

    tags = {
        Name = "PrivateSubnetCICD"
    }
} 

## Internet Gateway
resource "aws_internet_gateway" "CICD_InternetGW" {
    vpc_id = aws_vpc.vpc_cicd

    tags = {
        Name = "CICDInternetGateway"
    }
}


## Route Tables
### Main Table
resource "aws_default_route_table" "CICD_MainTable" {
    default_route_table_id = aws_vpc.vpc_cicd.default_route_table_id

    ## Routes
    route{
        cidr_block = "0.0.0.0/0"
        network_interface_id = ##TOBEDEFINE    
    }

    

    tags = {
        Name = "CICD_MainTable"
    }
}

### Public Table
resource "aws_route_table" "CICD_PublicTable" {
    vpc_id = aws_vpc.vpc_cicd.id

    ## Routes
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.CICD_InternetGW.id
    }
    route{
        cidr_block = "172.16.0.128/25"
        network_interface_id = ##TOBEDEFINE
    }
    tags = {
        Name = "CICD_PublicTable"
    }
}


## Subnet Associations
### Private subnet with main table
resource "aws_route_table_association" "CICD_Main_with_private" {
    subnet_id = aws_subnet.CICD_PrivateSubnet
    route_table_id = aws_vpc.vpc_cicd.default_route_table_id
}

### Public subnet with public table
resource "aws_route_table_association" "CICD_Public_with_public" {
    subnet_id = aws_subnet.CICD_PublicSubnet
    route_table_id = aws_route_table.CICD_PublicTable
}


## Security Groups
### Jenkins Master Security Group
resource "aws_security_group" "CICD_SG_JenkinsMaster" {
    name = "JenkinsMaster CICD"
    description = "Security Group for Jenkins Master"
    vpc_id = aws_vpc.vpc_cicd.id

  #inbound
    ingress {
        description = "Public SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "Web interface"
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "ICMPv4"
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

  #outbound
    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "JenkinsMaster SG"
    }
}


### Jenkins Slave SG
resource "aws_security_group" "CICD_SG_JenkinsSlave" {
    name = "JenkinsSlave CICD"
    description = "Security Group for Jenkins Slave"
    vpc_id = aws_vpc.vpc_cicd.id

  #inbound
    ingress {
        description = "Public SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "ICMPv4"
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

  #outbound
    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "JenkinsSlave SG"
    }
}


### WebServer SG
resource "aws_security_group" "CICD_SG_Web" {
    name = "Webserver CICD"
    description = "Security Group for Webserver CICD"
    vpc_id = aws_vpc.vpc_cicd.id

  #inbound
    ingress {
        description = "Public SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "ICMPv4"
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    #outbound
    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "Webserver SG"
    }
}