
### aws config
variable "profile" {
  type    = string
  default = "default"
}

variable "default-region" {
  type    = string
  default = "us-west-2"
}

variable "client_ip" {
  type    = string
  default = "0.0.0.0/0"
}

### cluster config
variable "vpc-cidr-block" {
  type    = string
  default = "10.240.0.0/16"
}

variable "subnet-count" {
  type    = number
  default = 3
}

variable "worker-count" {
  type    = number
  default = 3
}

variable "controller-count" {
  type    = number
  default = 3
}

### cluster nodes config
variable "worker-instance-type" {
  type    = string
  default = "t2.large"
}

variable "controller-instance-type" {
  type    = string
  default = "t2.large"
}

variable "controller-storage-size" {
  type    = number
  default = 100
}

variable "worker-storage-size" {
  type    = number
  default = 100
}


### terraform backend config
variable "backend-bucket" {
  type    = string
  default = "mlops-tf-bucket"
}

variable "backend-region" {
  type    = string
  default = "us-west-2"
}