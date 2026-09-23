
###################################################################################
# ROUTE TABLE RESOURCE - PUBLIC ROUTE TABLE (Routes out to the Internet Gateway)
###################################################################################

resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id # Points to your Internet Gateway
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-rt"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(var.public_subnet_ids)
  subnet_id      = var.public_subnet_ids[count.index]
  route_table_id = aws_route_table.public.id
}


###################################################################################
# ROUTE TABLE RESOURCE - PRIVATE ROUTE TABLES
# Private subnets have no direct Internet Gateway route.
# Optional outbound Internet access is provided through NAT Gateway(s) or a NAT
# instance.
###################################################################################

resource "aws_route_table" "private" {
  count = length(var.private_subnet_ids)

  vpc_id = var.vpc_id

  dynamic "route" {
    for_each = local.has_nat ? [1] : []

    content {
      cidr_block = "0.0.0.0/0"

      # A NAT Gateway, or a NAT instance's network interface: exactly one is set.
      nat_gateway_id = length(var.nat_gateway_ids) == 0 ? null : (
        var.nat_gateway_strategy == "single"
        ? var.nat_gateway_ids[0]
        : var.nat_gateway_ids[count.index]
      )

      network_interface_id = var.nat_network_interface_id
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-rt-${count.index + 1}"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_ids)

  subnet_id      = var.private_subnet_ids[count.index]
  route_table_id = aws_route_table.private[count.index].id
}

###################################################################################
# ROUTE TABLE RESOURCE - INTERNAL ROUTE TABLES
# Internal subnets have no direct Internet Gateway route.
# Optional outbound Internet access is provided through NAT Gateway(s) or a NAT
# instance.
###################################################################################

resource "aws_route_table" "internal" {
  count = length(var.internal_subnet_ids)

  vpc_id = var.vpc_id

  dynamic "route" {
    for_each = local.has_nat ? [1] : []

    content {
      cidr_block = "0.0.0.0/0"

      # A NAT Gateway, or a NAT instance's network interface: exactly one is set.
      nat_gateway_id = length(var.nat_gateway_ids) == 0 ? null : (
        var.nat_gateway_strategy == "single"
        ? var.nat_gateway_ids[0]
        : var.nat_gateway_ids[count.index]
      )

      network_interface_id = var.nat_network_interface_id
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-internal-rt-${count.index + 1}"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table_association" "internal" {
  count = length(var.internal_subnet_ids)

  subnet_id      = var.internal_subnet_ids[count.index]
  route_table_id = aws_route_table.internal[count.index].id
}


###################################################################################
# ROUTE TABLE RESOURCE - ISOLATED ROUTE TABLE
# Isolated subnets have no Internet Gateway or NAT Gateway route.
# AWS's implicit local route still permits VPC-local communication.
###################################################################################

resource "aws_route_table" "isolated" {
  vpc_id = var.vpc_id

  # Notice: There is NO 0.0.0.0/0 route here. 
  # AWS automatically creates an internal "local" route for VPC communication.

  tags = {
    Name        = "${var.project_name}-${var.environment}-isolated-rt"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table_association" "isolated_assoc" {
  count          = length(var.isolated_subnet_ids)
  subnet_id      = var.isolated_subnet_ids[count.index]
  route_table_id = aws_route_table.isolated.id
}
