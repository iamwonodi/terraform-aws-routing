variable "vpc_id" {
  description = "ID of the VPC."
  type        = string
}

variable "internet_gateway_id" {
  description = "ID of the VPC Internet Gateway."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs."
  type        = list(string)
}

variable "internal_subnet_ids" {
  description = "Internal subnet IDs."
  type        = list(string)
}

variable "isolated_subnet_ids" {
  description = "Isolated subnet IDs."
  type        = list(string)
}

variable "nat_gateway_ids" {
  description = "Optional NAT Gateway IDs."
  type        = list(string)
  default     = []
}