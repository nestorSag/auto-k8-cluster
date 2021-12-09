data "aws_availability_zones" "azs" {
  provider = aws.default-region
  state    = "available"
}

# create vpcs
resource "aws_vpc" "mlops-vpc" {
  provider             = aws.default-region
  cidr_block           = "10.240.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "mlops-vpc"
  }
}

# subnet 
resource "aws_subnet" "mlops-subnet" {
  provider          = aws.default-region
  availability_zone = data.aws_availability_zones.azs.names[0]
  vpc_id            = aws_vpc.mlops-vpc.id
  cidr_block        = "10.240.0.0/24"
}

# security groups
resource "aws_security_group" "mlops-internal" {
  provider    = aws.default-region
  name        = "mlops-internal"
  description = "Allow traffic between K8 nodes"
  vpc_id      = aws_vpc.mlops-vpc.id
  ingress {
    description = "Allow K8 port"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.240.0.0/24"]
  }
  ingress {
    description = "Allow HTTPS from subnet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.240.0.0/24"]

  }
  ingress {
    description = "Allow HTTP from subnet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.240.0.0/24"]

  }
  ingress {
    description = "Allow UDP from subnet"
    from_port   = 0
    to_port     = 0
    protocol    = "udp"
    cidr_blocks = ["10.240.0.0/24"]

  }
  egress {
    description = "Any"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "mlops-external" {
  provider    = aws.default-region
  name        = "mlops-external"
  description = "Allow traffic between K8 nodes"
  vpc_id      = aws_vpc.mlops-vpc.id
  ingress {
    description = "Allow K8 API calls"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.client_ip]
  }
  ingress {
    description = "Allow icmp"
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [var.client_ip]
  }
  ingress {
    description = "Allow SSH from public IP"
    from_port   = 22
    to_port     = 22
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