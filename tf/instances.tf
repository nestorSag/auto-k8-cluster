# node AMIs
data "aws_ssm_parameter" "linux-controller-ami" {
  provider = aws.default-region
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

data "aws_ssm_parameter" "linux-worker-ami" {
  provider = aws.default-region
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# create key pairs
resource "aws_key_pair" "controller-key" {
  provider   = aws.default-region
  key_name   = "controller-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_key_pair" "worker-key" {
  provider   = aws.default-region
  key_name   = "worker-key"
  public_key = file("~/.ssh/id_rsa.pub")
}


# create controller node instances
resource "aws_instance" "controller-nodes" {
  count                       = var.controller-count
  provider                    = aws.default-region
  ami                         = data.aws_ssm_parameter.linux-controller-ami.value
  instance_type               = var.controller-instance-type
  key_name                    = aws_key_pair.controller-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.k8-node-sg.id]
  subnet_id                   = aws_subnet.mlops-subnets[count.index % length(aws_subnet.mlops-subnets)].id
  #private_ip                 = ["10.240.0.1${count.index + 1}"]

  tags = {
    Name = "controller-node-${count.index + 1}"
  }

  # if custom route table fails, instances are not reachable from the internet
  depends_on = [aws_main_route_table_association.rt-assoc]

  root_block_device {
    volume_size = var.controller-storage-size
  }

}


# create controller node instances
resource "aws_instance" "worker-nodes" {
  count                       = var.worker-count
  provider                    = aws.default-region
  ami                         = data.aws_ssm_parameter.linux-worker-ami.value
  instance_type               = var.worker-instance-type
  key_name                    = aws_key_pair.worker-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.k8-node-sg.id]
  subnet_id                   = aws_subnet.mlops-subnets[count.index % length(aws_subnet.mlops-subnets)].id
  #private_ip                 = ["10.240.0.2${count.index + 1}"]

  tags = {
    Name = "worker-node-${count.index + 1}"
  }

  # if custom route table fails, instances are not reachable from the internet
  depends_on = [aws_main_route_table_association.rt-assoc]

  root_block_device {
    volume_size = var.controller-storage-size
  }


}



