variable "region" {
  description = "Specify AWS region"
  default     = "eu-west-3"
}

variable "environment" {
  description = "Deployment environment"
  default     = "production"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "aws_access_key" {
    description = "accesskey"
  
}

variable "aws_secret_key" {
  description = "secret key"
}