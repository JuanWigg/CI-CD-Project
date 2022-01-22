## Defines provider
provider "aws" {
    region = "us-east-1"
    shared_credentials_file = "/Users/Piche/.aws/credentials"
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
    vpc_id = aws_vpc.vpc_cicd.id
    cidr_block = "172.16.0.0/25"
    availability_zone = "us-east-1a"


    tags = {
        Name = "PublicSubnetCICD"
    }
}


### Private Subnet
resource "aws_subnet" "CICD_PrivateSubnet" {
    vpc_id = aws_vpc.vpc_cicd.id
    cidr_block = "172.16.0.128/25"
    availability_zone = "us-east-1a"

    tags = {
        Name = "PrivateSubnetCICD"
    }
} 

## Internet Gateway
resource "aws_internet_gateway" "CICD_InternetGW" {
    vpc_id = aws_vpc.vpc_cicd.id

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
        network_interface_id = aws_network_interface.jenkins_master_nic2.id
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
        network_interface_id = aws_network_interface.jenkins_master_nic1.id
    }
    tags = {
        Name = "CICD_PublicTable"
    }
}


## Subnet Associations
### Private subnet with main table
resource "aws_route_table_association" "CICD_Main_with_private" {
    subnet_id = aws_subnet.CICD_PrivateSubnet.id
    route_table_id = aws_vpc.vpc_cicd.default_route_table_id
}

### Public subnet with public table
resource "aws_route_table_association" "CICD_Public_with_public" {
    subnet_id = aws_subnet.CICD_PublicSubnet.id
    route_table_id = aws_route_table.CICD_PublicTable.id
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

## Network Interfaces
### Jenkins Master - It should have 2 interfaces. One private for the Jenkins Slave and another one in public.
resource "aws_network_interface" "jenkins_master_nic1" {
  subnet_id = aws_subnet.CICD_PublicSubnet.id
  private_ips = ["172.16.0.6"]
  security_groups = [aws_security_group.CICD_SG_JenkinsMaster.id]
  source_dest_check = false

}
resource "aws_network_interface" "jenkins_master_nic2" {
  subnet_id = aws_subnet.CICD_PrivateSubnet.id
  private_ips = ["172.16.0.136"]
  security_groups = [aws_security_group.CICD_SG_JenkinsMaster.id]
  source_dest_check = false
  
}


### Jenkins Slave - Just One on private subnet
resource "aws_network_interface" "jenkins_slave_nic1" {
  subnet_id = aws_subnet.CICD_PrivateSubnet.id
  private_ips = ["172.16.0.140"]
  security_groups = [aws_security_group.CICD_SG_JenkinsSlave.id]
  source_dest_check = false
  
}

### Webserver - One on public subnet
resource "aws_network_interface" "webserver_nic1" {
  subnet_id = aws_subnet.CICD_PublicSubnet.id
  private_ips = ["172.16.0.7"]
  security_groups = [aws_security_group.CICD_SG_Web.id]
  source_dest_check = false
  
}


### Elastic IPS - 
resource "aws_eip" "jenkinsmaster_eip"{
  vpc = true
  network_interface = aws_network_interface.jenkins_master_nic1.id
  associate_with_private_ip = "172.16.0.6"
  depends_on = [aws_internet_gateway.CICD_InternetGW, aws_instance.ec2_jenkins_master]
}



## EC2 Instances
### Jenkins master
resource "aws_instance" "ec2_jenkins_master"{
  ami = "ami-04505e74c0741db8d"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "DevOps2022"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.jenkins_master_nic1.id

  }
  network_interface {
    device_index = 1
    network_interface_id = aws_network_interface.jenkins_master_nic2.id
    
  }

  
  user_data = <<-EOF
                #!/bin/bash
                sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
                sudo apt-get update
                sudo apt-get install openjdk-11-jre-headless -y
                sudo wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
                sudo echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list
                sudo apt-get update
                sudo apt-get -y install jenkins 
                sudo systemctl start jenkins
                sudo echo '1'>/proc/sys/net/ipv4/ip_forward
                EOF


  tags = {
    Name = "CICDJenkinsMaster"
  }
}



### Jenkins Slave