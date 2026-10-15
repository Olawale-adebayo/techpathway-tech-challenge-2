variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used to name every resource (the Jenkinsfile expects the default)"
  type        = string
  default     = "techpathway"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the two public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "frontend_port" {
  description = "Port the frontend container listens on"
  type        = number
  default     = 80
}

variable "backend_port" {
  description = "Port the backend container listens on"
  type        = number
  default     = 8080
}

variable "task_cpu" {
  description = "Fargate CPU units per task"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate memory (MiB) per task"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of running tasks per service"
  type        = number
  default     = 1
}

variable "image_tag" {
  description = "Image tag the task definitions point at (the pipeline pushes :latest)"
  type        = string
  default     = "latest"
}
