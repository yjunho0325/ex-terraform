# variables.tf: 변수 정의(가변 값)
variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

# count
# variable "subnet_cidr" {
#   description = "Subnet CIDR blocks"
#   type        = list(list(string))
#   default = [
#     ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"],
#     ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
#   ]
# }

# for_each
variable "subnet_cidr" {
  description = "Subnet CIDR blocks"
  type        = list(map(string))
  default = [
    {
      ap-southeast-2a = "10.0.1.0/24",
      ap-southeast-2b = "10.0.2.0/24",
      ap-southeast-2c = "10.0.3.0/24"
    },
    {
      ap-southeast-2a = "10.0.11.0/24",
      ap-southeast-2b = "10.0.12.0/24",
      ap-southeast-2c = "10.0.13.0/24"
    }
  ]
}

variable "default_name" {
  description = "Default name for resources"
  type        = string
  default     = ""
}
