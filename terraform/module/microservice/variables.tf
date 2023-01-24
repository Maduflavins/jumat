variable "node_count" {
  description = "Number of nodes to deploy"
}

variable "subnet_id" {
  description = "VPC subnet_id to deploy nodes"
}

variable "security_group_ids" {
  type        = list(any)
  description = "Security group for the VPC network"
}

variable "node_name" {
  type        = list(any)
  description = "List of Elk node names"
}

variable "instance_type" {
  description = "EC2 instance type"
}