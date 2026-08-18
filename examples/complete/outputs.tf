output "public_route_table_id" {
  description = "ID of the public route table."
  value       = module.routing.public_route_table_id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables."
  value       = module.routing.private_route_table_ids
}

output "internal_route_table_ids" {
  description = "IDs of the internal route tables."
  value       = module.routing.internal_route_table_ids
}

output "isolated_route_table_id" {
  description = "ID of the isolated route table."
  value       = module.routing.isolated_route_table_id
}