locals {
  # Private and internal tables get a default route when there is a NAT to send
  # it to: NAT Gateway(s) or a NAT instance.
  has_nat = length(var.nat_gateway_ids) > 0 || var.nat_network_interface_id != null
}
