resource "aws_vpc" "infra_vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "dev-vpc"
  }
}

resource "aws_internet_gateway" "infra_igw" {
  vpc_id = aws_vpc.infra_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.infra_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.infra_vpc.cidr_block, 8, 0)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "dev-pub-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.infra_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.infra_vpc.cidr_block, 8, 1)
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "dev-pub-2"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.infra_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.infra_vpc.cidr_block, 8, 2)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "dev-priv-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.infra_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.infra_vpc.cidr_block, 8, 3)
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "dev-priv-2"
  }
}

resource "aws_eip" "eip_1" {
  domain = "vpc"
  depends_on = [
    aws_internet_gateway.infra_igw
  ]
}

resource "aws_eip" "eip_2" {
  domain = "vpc"
  depends_on = [
    aws_internet_gateway.infra_igw
  ]
}

resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.eip_1.id
  subnet_id     = aws_subnet.public_subnet_1.id

  depends_on = [
    aws_internet_gateway.infra_igw
  ]

  tags = {
    Name = "dev-NAT-1"
  }
}

resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.eip_2.id
  subnet_id     = aws_subnet.public_subnet_2.id

  depends_on = [
    aws_internet_gateway.infra_igw
  ]

  tags = {
    Name = "dev-NAT-2"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.infra_vpc.id

  tags = {
    Name = "dev-public-table"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.infra_igw.id
}

resource "aws_route_table" "private_rt_1" {
  vpc_id = aws_vpc.infra_vpc.id

  tags = {
    Name = "dev-priv-rt-1"
  }
}

resource "aws_route" "private_route_1" {
  route_table_id         = aws_route_table.private_rt_1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_1.id
}

resource "aws_route_table" "private_rt_2" {
  vpc_id = aws_vpc.infra_vpc.id

  tags = {
    Name = "dev-priv-rt-2"
  }
}

resource "aws_route" "private_route_2" {
  route_table_id         = aws_route_table.private_rt_2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_2.id
}

resource "aws_route_table_association" "pub1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "pub2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "priv1_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt_1.id
}

resource "aws_route_table_association" "priv2_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt_2.id
}