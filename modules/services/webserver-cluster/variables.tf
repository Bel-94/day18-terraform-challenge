variable "cluster_name" {
  description = "Base name for all resources in this cluster. Used as a prefix on every resource name."
  type        = string
}

# instance_type

variable "instance_type" {
  description = "EC2 instance type for the ASG launch template"
  type        = string
  default     = "t2.micro"

  validation {
    condition     = can(regex("^t[23]\\.", var.instance_type))
    error_message = "Instance type must be a t2 or t3 family type (e.g. t2.micro, t3.small)."
  }
}

# min_size

variable "min_size" {
  description = "Minimum number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 2

  validation {
    condition     = var.min_size >= 1
    error_message = "min_size must be at least 1."
  }
}

# max_size

variable "max_size" {
  description = "Maximum number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 4

  validation {
    condition     = var.max_size >= var.min_size
    error_message = "max_size must be greater than or equal to min_size."
  }
}

# environment

variable "environment" {
  description = "Deployment environment. Controls tagging and resource sizing."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

# server_port

variable "server_port" {
  description = "Port the web server listens on inside the EC2 instance"
  type        = number
  default     = 80
}

# ami_id

variable "ami_id" {
  description = "AMI ID for EC2 instances. Defaults to Amazon Linux 2 in us-east-1."
  type        = string
  default     = "ami-0c02fb55956c7d316"
}

# project_name

variable "project_name" {
  description = "Project name — applied as a tag to all resources"
  type        = string
  default     = "30-Day Terraform Challenge"
}

# team_name

variable "team_name" {
  description = "Team or engineer name — applied as the Owner tag"
  type        = string
  default     = "Belinda Ntinyari"
}

# cpu_alarm_threshold

variable "cpu_alarm_threshold" {
  description = "CPU utilisation percentage that triggers the high-CPU CloudWatch alarm"
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_alarm_threshold > 0 && var.cpu_alarm_threshold <= 100
    error_message = "cpu_alarm_threshold must be between 1 and 100."
  }
}

# log_retention_days

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365], var.log_retention_days)
    error_message = "log_retention_days must be a value accepted by CloudWatch: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, or 365."
  }
}
