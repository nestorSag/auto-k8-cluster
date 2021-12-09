
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

### cluster size config
variable "worker-count" {
  type    = number
  default = 3
}

variable "controller-count" {
  type    = number
  default = 1
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