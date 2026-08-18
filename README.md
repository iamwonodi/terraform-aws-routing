
# Terraform AWS Routing Module

A reusable Terraform module for creating and managing AWS route tables and subnet associations across public, private, internal, and isolated subnet tiers.

The module is designed to work as part of a larger modular AWS infrastructure architecture where the VPC, subnets, NAT Gateways, and routing layer can be managed independently.

## Overview

This module creates the routing layer for an existing VPC.

It does not create the VPC, subnets, Internet Gateway, NAT Gateways, or Elastic IP addresses.

Instead, it consumes the IDs of infrastructure created by other modules and creates the appropriate route tables, routes, and subnet associations.

The module supports four subnet tiers:

- Public

- Private

- Internal

- Isolated

Private and internal route tables can optionally use NAT Gateway infrastructure supplied by the caller.

NAT Gateway resources are intentionally managed outside this module.

This separation allows NAT Gateway infrastructure to be provisioned, shared, or temporarily removed without requiring the routing or subnet infrastructure to be destroyed.

## Architecture

The routing module expects the VPC and subnet infrastructure to already exist.

The intended architecture is:

```text

VPC

|

+-----------------+------------------+

| | |

Public Private Internal

| | |

v v v

Public RT Private RTs Internal RTs

| | |

| +--------+---------+

| |

v v

IGW Optional NAT

|

v

IGW

Isolated

|

v

Isolated RT

|

v

Local VPC only

The routing module does not provision the Internet Gateway or NAT Gateway.

The Internet Gateway is supplied through:

hcl

internet_gateway_id = module.vpc_base.internet_gateway_id

NAT Gateway IDs are supplied through:

hcl

nat_gateway_ids = module.nat_gateway.nat_gateway_ids

### Subnet Tier Behavior

### Public

Public subnets use a shared route table.

The public route table contains a default route to the VPC Internet Gateway:

0.0.0.0/0 → Internet Gateway

All public subnets are associated with this route table.

Conceptually:

Public Subnet A ─┐

Public Subnet B ─┼──→ Public Route Table ──→ IGW

Public Subnet C ─┘

The public route table is shared because the Internet Gateway is not AZ-specific.

### Private

Private subnets receive one route table per subnet/AZ.

When NAT Gateway IDs are supplied, the private route tables can provide outbound Internet access through the configured NAT Gateway strategy.

With a single NAT Gateway:

Private-A ─┐

Private-B ─┼──→ NAT-A ──→ IGW

Private-C ─┘

With NAT Gateways per AZ:

Private-A ──→ NAT-A ──→ IGW

Private-B ──→ NAT-B ──→ IGW

Private-C ──→ NAT-C ──→ IGW

When no NAT Gateway IDs are supplied, the private route tables are still created and associated with their subnets, but no NAT Gateway default route is added.

### Internal

Internal subnets are also assigned route tables on a per-subnet/AZ basis.

They can optionally use NAT Gateway infrastructure for outbound Internet access.

The routing behavior follows the configured NAT Gateway strategy.

Without NAT Gateway IDs, the internal route tables remain functional for VPC-local routing but do not receive a NAT Gateway default route.

### Isolated

Isolated subnets use a shared route table.

The isolated route table does not contain an Internet Gateway or NAT Gateway default route.

The AWS-provided local VPC route remains available, allowing communication between resources using the VPC's local routing.

Conceptually:

Isolated-A ─┐

Isolated-B ─┼──→ Isolated Route Table

Isolated-C ─┘

The isolated tier is intended for workloads that should not have direct or NAT-based Internet egress.

### NAT Gateway Integration

NAT Gateway resources are intentionally excluded from this module.

This module only consumes NAT Gateway IDs.

This design keeps NAT Gateway lifecycle and routing lifecycle independent.

The caller can therefore choose whether NAT infrastructure exists without changing the subnet architecture.

### No NAT Gateway

NAT Gateway usage is optional.

The following is valid:

hcl

nat_gateway_ids = []

When the list is empty:

* Private route tables are still created.

* Internal route tables are still created.

* Subnet associations remain intact.

* No NAT Gateway route is created.

* VPC-local routing remains available.

This is useful when NAT Gateway access is only required temporarily.

For example:

Deploy infrastructure

|

v

Create NAT Gateway

|

v

Install/update resources

|

v

Remove NAT Gateway

|

v

Private/Internal subnets remain

This can significantly reduce unnecessary NAT Gateway operating costs when Internet egress is only required during provisioning or maintenance.

### Single NAT Gateway

The single NAT Gateway strategy uses one NAT Gateway for all private and internal route tables.

Configure:

hcl

nat_gateway_strategy = "single"

nat_gateway_ids = [

"nat-0123456789abcdef"

]

The resulting routing behavior is:

Private-A ─┐

Private-B ─┼──→ NAT-A

Private-C ─┘

Internal-A ─┐

Internal-B ─┼──→ NAT-A

Internal-C ─┘

This strategy reduces NAT Gateway cost but creates a centralized NAT egress point.

### NAT Gateway Per AZ

The `per_az` strategy associates NAT Gateways with route tables according to their position in the supplied lists.

Example:

hcl

nat_gateway_strategy = "per_az"

nat_gateway_ids = [

"nat-aaaa",

"nat-bbbb",

"nat-cccc"

]

With three subnet/AZ positions:

Private-A → NAT-A

Private-B → NAT-B

Private-C → NAT-C

Internal-A → NAT-A

Internal-B → NAT-B

Internal-C → NAT-C

The NAT Gateway list must contain enough NAT Gateway IDs to satisfy the private and internal subnet tiers.

This strategy provides AZ-local NAT routing and avoids making every private/internal subnet dependent on a single NAT Gateway.

### Usage

A typical consumer configuration looks like:

hcl

module "routing" {

source = "git::[https://github.com/iamwonodi/terraform-aws-routing.git?ref=v1.0.0](https://github.com/iamwonodi/terraform-aws-routing.git?ref=v1.0.0)"

project_name = "example"

environment = "prod"

vpc_id = module.vpc_base.vpc_id

internet_gateway_id = module.vpc_base.internet_gateway_id

public_subnet_ids = module.vpc_base.public_subnet_ids

private_subnet_ids = module.vpc_base.private_subnet_ids

internal_subnet_ids = module.vpc_base.internal_subnet_ids

isolated_subnet_ids = module.vpc_base.isolated_subnet_ids

nat_gateway_strategy = "single"

nat_gateway_ids = module.nat_gateway.nat_gateway_ids

}

If NAT is not required:

hcl

module "routing" {

source = "git::[https://github.com/iamwonodi/terraform-aws-routing.git?ref=v1.0.0](https://github.com/iamwonodi/terraform-aws-routing.git?ref=v1.0.0)"

project_name = "example"

environment = "prod"

vpc_id = module.vpc_base.vpc_id

internet_gateway_id = module.vpc_base.internet_gateway_id

public_subnet_ids = module.vpc_base.public_subnet_ids

private_subnet_ids = module.vpc_base.private_subnet_ids

internal_subnet_ids = module.vpc_base.internal_subnet_ids

isolated_subnet_ids = module.vpc_base.isolated_subnet_ids

nat_gateway_ids = []

}

### Integration With VPC Base

The routing module is designed to consume outputs from the VPC base module.

A typical architecture is:

vpc_base

|

+--------------+--------------+

| | |

v v v

VPC Subnets IGW

| | |

+--------------+--------------+

|

v

routing

|

+------------+------------+

| | |

Public Private Internal

Routes Routes Routes

|

v

nat_gateway

The VPC base module is responsible for creating:

* VPC

* Availability Zone layout

* Subnets

* Internet Gateway

* Related foundational networking resources

The routing module consumes those resources.

Example:

hcl

module "vpc_base" {

source = "git::[https://github.com/iamwonodi/terraform-aws-vpc-base.git?ref=v1.0.0](https://github.com/iamwonodi/terraform-aws-vpc-base.git?ref=v1.0.0)"

# VPC configuration

}

Then:

hcl

module "routing" {

source = "git::[https://github.com/iamwonodi/terraform-aws-routing.git?ref=v1.0.0](https://github.com/iamwonodi/terraform-aws-routing.git?ref=v1.0.0)"

project_name = "example"

environment = "prod"

vpc_id = module.vpc_base.vpc_id

internet_gateway_id = module.vpc_base.internet_gateway_id

public_subnet_ids = module.vpc_base.public_subnet_ids

private_subnet_ids = module.vpc_base.private_subnet_ids

internal_subnet_ids = module.vpc_base.internal_subnet_ids

isolated_subnet_ids = module.vpc_base.isolated_subnet_ids

nat_gateway_ids = []

nat_gateway_strategy = "single"

}

The exact output names must correspond to the outputs exposed by the VPC base module.

### NAT Gateway Lifecycle

NAT Gateway infrastructure is deliberately separated from routing.

This allows the caller to provision NAT infrastructure only when required.

For example, a temporary NAT deployment can be used for:

* Package installation

* Operating system updates

* Application dependency downloads

* Bootstrap operations

* Configuration management

* Temporary outbound connectivity

After those operations are complete, the NAT Gateway can be removed while retaining:

* The VPC

* The subnets

* The route tables

* The route table associations

* The workload resources

When the NAT Gateway is removed, the caller simply supplies:

hcl

nat_gateway_ids = []

The routing module then removes the NAT-based default routes.

This design also avoids forcing the routing module to own NAT Gateway resources and their associated Elastic IP addresses.

### Inputs

| Name                 | Description                                                   | Type         | Default  | Required |
| -------------------- | ------------------------------------------------------------- | ------------ | -------- | -------- |
| project_name         | Project or workload name used for resource naming and tagging | string       | n/a      | yes      |
| environment          | Deployment environment used for resource naming and tagging   | string       | n/a      | yes      |
| vpc_id               | ID of the VPC where route tables are created                  | string       | n/a      | yes      |
| internet_gateway_id  | ID of the VPC Internet Gateway used by public routes          | string       | n/a      | yes      |
| public_subnet_ids    | IDs of public subnets                                         | list(string) | n/a      | yes      |
| private_subnet_ids   | IDs of private subnets                                        | list(string) | n/a      | yes      |
| internal_subnet_ids  | IDs of internal subnets                                       | list(string) | n/a      | yes      |
| isolated_subnet_ids  | IDs of isolated subnets                                       | list(string) | n/a      | yes      |
| nat_gateway_ids      | Optional NAT Gateway IDs used by private and internal routes  | list(string) | []       | no       |
| nat_gateway_strategy | NAT Gateway routing strategy: single or per_az                | string       | "single" | no       |

### Outputs

| Name                     | Description                                                       |
| ------------------------ | ----------------------------------------------------------------- |
| public_route_table_id    | ID of the shared public route table                               |
| private_route_table_ids  | IDs of private route tables ordered to match private_subnet_ids   |
| internal_route_table_ids | IDs of internal route tables ordered to match internal_subnet_ids |
| isolated_route_table_id  | ID of the shared isolated route table                             |

### Requirements

| Name         | Version    |
| ------------ | ---------- |
| Terraform    | >= 1.6.0   |
| AWS Provider | `>= 6.0.0, |
