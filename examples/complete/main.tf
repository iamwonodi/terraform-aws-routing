module "routing" {
  source = "git::https://github.com/iamwonodi/terraform-aws-routing.git?ref=v1.0.0"

  project_name = "example"
  environment  = "dev"

  vpc_id = var.vpc_id

  internet_gateway_id = var.internet_gateway_id

  public_subnet_ids   = var.public_subnet_ids
  private_subnet_ids  = var.private_subnet_ids
  internal_subnet_ids = var.internal_subnet_ids
  isolated_subnet_ids = var.isolated_subnet_ids

  nat_gateway_ids      = var.nat_gateway_ids
  nat_gateway_strategy = "single"
}