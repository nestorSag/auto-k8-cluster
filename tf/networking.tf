data "aws_availability_zones" "azs" {
  provider = aws.default-region
  state    = "available"
}

# create vpcs
resource "aws_vpc" "mlops-vpc" {
  provider             = aws.default-region
  cidr_block           = var.vpc-cidr-block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "mlops-vpc"
  }
}

# subnet 
resource "aws_subnet" "mlops-subnets" {
  count             = var.subnet-count
  provider          = aws.default-region
  availability_zone = data.aws_availability_zones.azs.names[count.index]
  vpc_id            = aws_vpc.mlops-vpc.id
  cidr_block        = "10.240.${count.index}.0/24"
}

# security groups
/*resource "aws_security_group" "load-balancer-sg" {
  provider    = aws.default-region
  name        = "load balancer security group"
  description = "Allow traffic from the internet and to K8 control plane"
  vpc_id      = aws_vpc.mlops-vpc.id
  ingress {
    description = "Allow any traffic from the Internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow to redirection to K8 control plane"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc-cidr-block]
  }
}*/


resource "aws_security_group" "k8-node-sg" {
  provider    = aws.default-region
  name        = "k8-node-sg"
  description = "Allow traffic between K8 nodes"
  vpc_id      = aws_vpc.mlops-vpc.id
/*  ingress {
    description = "Allow ingress from load balancer as only valid ingress from the Internet other than SSH"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.load-balancer-sg.id]
  }*/
  ingress {
    description = "Allow all inter-node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self = true
  }
  ingress {
    description = "Allow icmp from anywhere"
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [var.client_ip]
  }
  ingress {
    description = "Allow SSH ingress from the Internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.client_ip]
  }
  egress {
    description = "Allow all inter-node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self = true
  }
  egress {
    description = "Allow Internet egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "control-plane-sg" {
  provider    = aws.default-region
  name        = "k8-control-plane-sg"
  description = "Allow traffic between K8 nodes"
  vpc_id      = aws_vpc.mlops-vpc.id
  ingress {
    description = "Allow health checks from NLB"
    from_port   = 0
    to_port     = 80
    protocol    = "tcp"
    self = true
  }
  ingress {
    description = "Allow API calls from NLB"
    from_port   = 0
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.client_ip]
  }
}


resource "aws_internet_gateway" "mlops-vpc-gateway" {
  provider = aws.default-region
  vpc_id   = aws_vpc.mlops-vpc.id

}

# create routing tables in master region
resource "aws_route_table" "mlops-vpc-route-table" {
  provider = aws.default-region
  vpc_id   = aws_vpc.mlops-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mlops-vpc-gateway.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "mlops-vpc-route-table"
  }
}

# overwrite default route table in master region
resource "aws_main_route_table_association" "rt-assoc" {
  provider       = aws.default-region
  vpc_id         = aws_vpc.mlops-vpc.id
  route_table_id = aws_route_table.mlops-vpc-route-table.id
}
