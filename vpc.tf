# vpc creation block
resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = merge(
    var.aws_vpc_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}"
    }
  )
}

# creates internet gateway and attaches to the vpc.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.aws_igw_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}"
    }
  )
}

# creates subnets in the given vpc in different available zones(these block creates on two availble zones)
resource "aws_subnet" "public" {
    count = length(var.public_subnet_cidr_block_ids)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr_block_ids[count.index]
  availability_zone = local.availability_zone[count.index]

  map_public_ip_on_launch = true

  tags = merge(
    var.public_subnet_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-public-${local.availability_zone[count.index]}"
    }
  )
}

#private subnets
resource "aws_subnet" "private" {
    count = length(var.private_subnet_cidr_block_ids)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr_block_ids[count.index]
  availability_zone = local.availability_zone[count.index]

  tags = merge(
    var.private_subnet_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-private-${local.availability_zone[count.index]}"
    }
  )
}

#database subnets
resource "aws_subnet" "database" {
    count = length(var.database_subnet_cidr_block_ids)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_subnet_cidr_block_ids[count.index]
  availability_zone = local.availability_zone[count.index]

  tags = merge(
    var.database_subnet_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-database-${local.availability_zone[count.index]}"
    }
  )
}

# create elastic ip 
resource "aws_eip" "nat" {
  domain   = "vpc"

  tags = merge(
    var.eip_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}"
    }
  )
}

#create nat gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    var.nat_gateway_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}"
    }
  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}

# create route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.public_route_table_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-public"
    }
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.private_route_table_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-private"
    }
  )
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.database_route_table_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-database"
    }
  )
}

#add routes to the route-tables
resource "aws_route" "public" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}

resource "aws_route" "private" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.main.id
}

resource "aws_route" "database" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.main.id
}

# subnet association with the route tables
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr_block_ids)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidr_block_ids)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  count = length(var.database_subnet_cidr_block_ids)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}