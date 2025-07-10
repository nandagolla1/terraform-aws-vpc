output "available_zones" {
  value = data.aws_availability_zones.available.names
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_list" {
  value = aws_subnet.public[*].id
}

output "private_subnet_list" {
  value = aws_subnet.private[*].id
}

output "database_subnet_list" {
  value = aws_subnet.database[*].id
}