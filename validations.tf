resource "terraform_data" "validation" {
  input = {
    public_subnets   = length(var.public_subnet_ids)
    private_subnets  = length(var.private_subnet_ids)
    internal_subnets = length(var.internal_subnet_ids)
    isolated_subnets = length(var.isolated_subnet_ids)
    nat_gateways     = length(var.nat_gateway_ids)
  }

  lifecycle {
    precondition {
      condition = (
        length(var.public_subnet_ids) == length(var.private_subnet_ids) &&
        length(var.public_subnet_ids) == length(var.internal_subnet_ids) &&
        length(var.public_subnet_ids) == length(var.isolated_subnet_ids)
      )

      error_message = "Public, private, internal, and isolated subnet ID lists must contain the same number of subnets."
    }

    precondition {
      condition = (
        length(var.nat_gateway_ids) == 0 ||
        var.nat_gateway_strategy == "single" ||
        length(var.nat_gateway_ids) >= max(
          length(var.private_subnet_ids),
          length(var.internal_subnet_ids)
        )
      )

      error_message = "The per_az NAT strategy requires at least one NAT Gateway ID for every private and internal subnet/AZ."
    }
  }
}