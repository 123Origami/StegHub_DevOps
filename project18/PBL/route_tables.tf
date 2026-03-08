# Public route table
resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = format("%s-Public-RT", var.name)
  })
}

# Public route to Internet Gateway
resource "aws_route" "public-route" {
  route_table_id         = aws_route_table.public-rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

# Associate public subnets
resource "aws_route_table_association" "public-assoc" {
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public-rtb.id
}

# Private route table
resource "aws_route_table" "private-rtb" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = format("%s-Private-RT", var.name)
  })
}

# Private route to NAT Gateway
resource "aws_route" "private-route" {
  route_table_id         = aws_route_table.private-rtb.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Associate private subnets
resource "aws_route_table_association" "private-assoc" {
  count = length(aws_subnet.private)
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private-rtb.id
}