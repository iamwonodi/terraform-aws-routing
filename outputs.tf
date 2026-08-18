output "public_route_table_id" {
  description = "ID of the shared public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables, ordered to match private_subnet_ids."
  value       = aws_route_table.private[*].id
}

output "internal_route_table_ids" {
  description = "IDs of the internal route tables, ordered to match internal_subnet_ids."
  value       = aws_route_table.internal[*].id
}

output "isolated_route_table_id" {
  description = "ID of the shared isolated route table."
  value       = aws_route_table.isolated.id
}