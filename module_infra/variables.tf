variable "region" {
  type = string
}

variable "instance_type" {
  description = "The instance type"
  type        = string
  default     = "t3.micro"
}

variable "endpoint" {
  type = string
}