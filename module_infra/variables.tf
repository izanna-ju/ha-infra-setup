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

variable "environment_name" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "object_path" {
  description = "path of folder to upload"
  default     = "./barista_cafe"
}