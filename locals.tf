locals {
  common_tags = {
    project = var.project
    environment = var.environment
    Terraform = true
  }
}

locals {
  availability_zone = slice(data.aws_availability_zones.available.names, 0, 2)
}