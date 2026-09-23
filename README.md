# Terraform AWS Routing Module

Reusable Terraform module for the route tables and subnet associations of a four-tier VPC: public, private, internal and isolated.

It creates the routing layer for an existing VPC. It does **not** create the VPC, the subnets, the Internet Gateway, NAT Gateways, NAT instances or Elastic IPs; it consumes their IDs. NAT infrastructure stays outside the module, so it can be provisioned, shared, replaced or removed without touching routing or subnets.

---

# Architecture

```text
                               VPC
                                |
     +---------------+----------+-----------+----------------+
     |               |                      |                |
   Public         Private               Internal          Isolated
     |               |                      |                |
 Public RT      Private RTs            Internal RTs      Isolated RT
 (shared)       (one per AZ)           (one per AZ)       (shared)
     |               |                      |                |
    IGW              +---------+------------+           local only
                               |
                  NAT Gateway(s) or NAT instance
                        (optional, caller's)
```

| Tier | Route tables | Default route |
| --- | --- | --- |
| Public | one, shared | `0.0.0.0/0` to the Internet Gateway |
| Private | one per subnet (AZ) | to the NAT, when one is supplied |
| Internal | one per subnet (AZ) | to the NAT, when one is supplied |
| Isolated | one, shared | none: only the VPC's local route |

The public route table is shared because the Internet Gateway is not zone-specific. Private and internal route tables are per zone so each can use its own zone's NAT Gateway. The isolated tier never routes out; it is for workloads that must have no internet egress, directly or through NAT.

---

# NAT options

Private and internal tables send outbound traffic to whichever NAT the caller supplies, or nowhere.

| Option | Inputs | Default route |
| --- | --- | --- |
| No NAT | neither | none; the tables still exist for VPC-local routing |
| One NAT Gateway | `nat_gateway_ids = [id]`, `nat_gateway_strategy = "single"` | every table to that gateway |
| NAT Gateway per AZ | `nat_gateway_ids = [a, b, c]`, `nat_gateway_strategy = "per_az"` | each table to its zone's gateway |
| NAT instance | `nat_network_interface_id = eni-...` | every table to the instance's network interface |

A NAT instance is far cheaper than a NAT Gateway (no per-GB processing charge) at the price of throughput and availability: its traffic stops while it is replaced. Route to its **network interface**, not the instance, so the route survives the instance being replaced when the interface is kept.

Set `nat_gateway_ids` or `nat_network_interface_id`, never both: a route table has one default route.

---

# Usage

## One NAT Gateway

```hcl
module "routing" {
  source = "git::https://github.com/iamwonodi/terraform-aws-routing.git?ref=v1.1.0"

  project_name = "acme"
  environment  = "production"

  vpc_id              = module.vpc_base.vpc_id
  internet_gateway_id = module.vpc_base.internet_gateway_id

  public_subnet_ids   = module.vpc_base.public_subnet_ids
  private_subnet_ids  = module.vpc_base.private_subnet_ids
  internal_subnet_ids = module.vpc_base.internal_subnet_ids
  isolated_subnet_ids = module.vpc_base.isolated_subnet_ids

  nat_gateway_ids      = module.nat_gateway.nat_gateway_ids
  nat_gateway_strategy = "single"
}
```

## NAT instance

```hcl
module "routing" {
  source = "git::https://github.com/iamwonodi/terraform-aws-routing.git?ref=v1.1.0"

  project_name = "acme"
  environment  = "staging"

  vpc_id              = module.vpc_base.vpc_id
  internet_gateway_id = module.vpc_base.internet_gateway_id

  public_subnet_ids   = module.vpc_base.public_subnet_ids
  private_subnet_ids  = module.vpc_base.private_subnet_ids
  internal_subnet_ids = module.vpc_base.internal_subnet_ids
  isolated_subnet_ids = module.vpc_base.isolated_subnet_ids

  nat_network_interface_id = module.nat_instance.network_interface_id
}
```

## No NAT

Omit both `nat_gateway_ids` and `nat_network_interface_id`. The tables and associations are still created.

---

# Validation

Refused at plan time:

* public, private, internal and isolated subnet lists of different lengths;
* `nat_gateway_strategy = "per_az"` with fewer NAT Gateway IDs than private or internal subnets;
* `nat_gateway_ids` and `nat_network_interface_id` together;
* a `nat_network_interface_id` that is not a network interface ID;
* a `nat_gateway_strategy` other than `single` or `per_az`.

---

# Inputs

| Name | Description | Type | Default | Required |
| --- | --- | --- | --- | --- |
| `project_name` | Project name, for naming and tagging | `string` | n/a | yes |
| `environment` | Environment, for naming and tagging | `string` | n/a | yes |
| `vpc_id` | VPC the route tables are created in | `string` | n/a | yes |
| `internet_gateway_id` | Internet Gateway for the public route | `string` | n/a | yes |
| `public_subnet_ids` | Public subnets | `list(string)` | n/a | yes |
| `private_subnet_ids` | Private subnets | `list(string)` | n/a | yes |
| `internal_subnet_ids` | Internal subnets | `list(string)` | n/a | yes |
| `isolated_subnet_ids` | Isolated subnets | `list(string)` | n/a | yes |
| `nat_gateway_ids` | NAT Gateways for private and internal routes | `list(string)` | `[]` | no |
| `nat_gateway_strategy` | `single` or `per_az` | `string` | `"single"` | no |
| `nat_network_interface_id` | A NAT instance's network interface, instead of NAT Gateways | `string` | `null` | no |

# Outputs

| Name | Description |
| --- | --- |
| `public_route_table_id` | The shared public route table |
| `private_route_table_ids` | Private route tables, in the order of `private_subnet_ids` |
| `internal_route_table_ids` | Internal route tables, in the order of `internal_subnet_ids` |
| `isolated_route_table_id` | The shared isolated route table |

---

# Requirements

| Name | Version |
| --- | --- |
| Terraform | `>= 1.6.0` (`terraform test` needs 1.7 or later) |
| AWS Provider | `>= 6.0.0, < 7.0.0` |

---

# Module Structure

```text
terraform-aws-routing/
├── README.md
├── versions.tf
├── variables.tf
├── locals.tf
├── data.tf
├── main.tf
├── validations.tf
├── outputs.tf
├── tests/
│   └── routes.tftest.hcl
└── examples/
```

Run the tests with `terraform init -backend=false && terraform test`; the provider is mocked.

---

# Versioning

Semantic Versioning; consume by tag.

Current release: `v1.1.0`, which adds `nat_network_interface_id` (a NAT instance as the default route). It is backward compatible: callers of v1.0.0 see no change.

---

# License

Provided for reusable AWS infrastructure deployments, to be consumed as a versioned Terraform module.
