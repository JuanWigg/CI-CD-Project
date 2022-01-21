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