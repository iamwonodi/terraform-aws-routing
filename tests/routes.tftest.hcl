mock_provider "aws" {}

variables {
  project_name        = "acme"
  environment         = "staging"
  vpc_id              = "vpc-0abc"
  internet_gateway_id = "igw-0abc"
  public_subnet_ids   = ["subnet-p1", "subnet-p2"]
  private_subnet_ids  = ["subnet-r1", "subnet-r2"]
  internal_subnet_ids = ["subnet-i1", "subnet-i2"]
  isolated_subnet_ids = ["subnet-s1", "subnet-s2"]
}

run "nat_gateway_route_is_unchanged" {
  command = plan
  variables { nat_gateway_ids = ["nat-0abc"] }
  assert {
    condition     = alltrue([for t in concat(aws_route_table.private, aws_route_table.internal) : one(t.route).nat_gateway_id == "nat-0abc" && one(t.route).network_interface_id == null])
    error_message = "a NAT Gateway is the default route, as in v1.0.0"
  }
}

run "nat_instance_route" {
  command = plan
  variables { nat_network_interface_id = "eni-0abc" }
  assert {
    condition     = alltrue([for t in concat(aws_route_table.private, aws_route_table.internal) : one(t.route).network_interface_id == "eni-0abc" && one(t.route).nat_gateway_id == null && one(t.route).cidr_block == "0.0.0.0/0"])
    error_message = "a NAT instance's interface is the default route"
  }
}

# Without a NAT the route tables are declared with no route at all. Terraform
# cannot see a computed route set during a plan, so this checks the decision
# the tables are built from.
run "no_nat_no_default_route" {
  command = plan

  assert {
    condition     = local.has_nat == false
    error_message = "without a NAT there is no default route"
  }
}

run "both_are_refused" {
  command = plan
  variables {
    nat_gateway_ids          = ["nat-0abc"]
    nat_network_interface_id = "eni-0abc"
  }
  expect_failures = [terraform_data.validation]
}

run "a_malformed_interface_is_refused" {
  command = plan
  variables { nat_network_interface_id = "nat-0abc" }
  expect_failures = [var.nat_network_interface_id]
}
