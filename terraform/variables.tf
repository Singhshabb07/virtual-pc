variable "aws_region" {
  description = "AWS region for Cloud PC deployment (PRD specifies Mumbai / ap-south-1 subject to GPU availability)"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "mvp"
}

variable "instance_type" {
  description = "EC2 Instance type for GPU computing (PRD candidate: g4dn.xlarge with 4 vCPU, 16 GB RAM, NVIDIA T4)"
  type        = string
  default     = "g4dn.xlarge"
}

variable "os_type" {
  description = "Target operating system: 'windows' (Windows Server 2022) or 'ubuntu' (Ubuntu 22.04 LTS)"
  type        = string
  default     = "windows"
  validation {
    condition     = contains(["windows", "ubuntu"], var.os_type)
    error_message = "os_type must be either 'windows' or 'ubuntu'."
  }
}

variable "custom_ami_id" {
  description = "Optional override for EC2 AMI. If left empty, latest official AMI will be resolved automatically."
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Size of the OS root EBS gp3 volume in GB"
  type        = number
  default     = 100
}

variable "data_volume_size" {
  description = "Size of the persistent secondary data EBS gp3 volume in GB (100GB root + 400GB data = 500GB storage target)"
  type        = number
  default     = 400
}

variable "allowed_client_cidr" {
  description = "Allowed CIDR block for Sunshine streaming and management ports. Set to your public IP (e.g. '203.0.113.50/32') for highest security."
  type        = string
  default     = "0.0.0.0/0"
}

variable "monthly_budget_usd" {
  description = "Hard constraint monthly budget in USD (~$70 USD equals PRD ₹6,000 INR limit at current conversion rates)"
  type        = number
  default     = 70
}

variable "notification_email" {
  description = "Email address for AWS Budget alerts, CloudWatch alarms, and cost threshold notifications"
  type        = string
  default     = "admin@codevern.com"
}

variable "idle_timeout_minutes" {
  description = "Number of inactive minutes before in-guest idle daemon initiates system shutdown"
  type        = number
  default     = 15
}

variable "use_spot_instance" {
  description = "Whether to use an EC2 Spot instance instead of On-Demand to dramatically reduce hourly GPU compute cost"
  type        = bool
  default     = false
}
