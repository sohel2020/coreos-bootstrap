variable "access_key" {
  default = ""
}

variable "secret_key" {
  default = ""
}

variable "subnets" {
  default = ["subnet-addf74db", "subnet-e74af383"]
}

variable "ec2_key_name" {
  default = "jumpbox-key-pair"
}

variable "iam_profile" {
  default = "user-management-role"
}

variable "ami_id" {
  default = "ami-006b1ac0974ddc205"
}

variable "vpc_id" {
  default = "vpc-308f4a54"
}

variable "vpc_cidr" {
  default = "172.32.0.0/16"
}

variable "service_component" {
  default = "telenorhealth-workload"
}

variable "instance_type" {
  default = "t2.small"
}

variable "region" {
  default = "ap-southeast-1"
}

variable "env" {
  default = "production"
}

variable "service_name" {
  default = "ec2"
}

variable "ebs_size" {
  default = "20"
}
