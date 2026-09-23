variable "project_name" {
  description = "Project name used for resource naming and tagging."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC containing the subnets and route tables."
  type        = string
}

variable "internet_gateway_id" {
  description = "ID of the Internet Gateway attached to the VPC."
  type        = string
}

variable "nat_gateway_ids" {
  description = "NAT Gateway IDs used by private and internal route tables."
  type        = list(string)
  default     = []
}

variable "nat_gateway_strategy" {
  description = "How NAT Gateway IDs are applied to private and internal routes."
  type        = string
  default     = "single"

  validation {
    condition = contains(
      ["single", "per_az"],
      var.nat_gateway_strategy
    )

    error_message = "nat_gateway_strategy must be either single or per_az."
  }
}

variable "nat_network_interface_id" {
  description = "Network interface of a NAT instance that private and internal route tables send outbound traffic to, instead of a NAT Gateway. Use one or the other, not both."
  type        = string
  default     = null

  validation {
    condition     = var.nat_network_interface_id == null || can(regex("^eni-[0-9a-f]+$", coalesce(var.nat_network_interface_id, "x")))
    error_message = "nat_network_interface_id must be a network interface ID (eni-...)."
  }
}

variable "public_subnet_ids" {
  description = "IDs of public subnets."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs of private subnets."
  type        = list(string)
}

variable "internal_subnet_ids" {
  description = "IDs of internal subnets."
  type        = list(string)
}

variable "isolated_subnet_ids" {
  description = "IDs of isolated subnets."
  type        = list(string)
}