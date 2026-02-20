# --- Data Source: Fetch Available Zones ---
data "aws_availability_zones" "available" {
  state = "available"
}

# --- 1. VPC ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.project_name}-vpc-${var.environment}"
    Project = var.project_name
  }
}

# --- 2. Internet Gateway ---
# Required for the ALBs and for the EC2s to pull updates/S3 backups
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-igw-${var.environment}"
    Project = var.project_name
  }
}

# --- 3. Public Subnets (x2) ---
# Created in different AZs to support ALB High Availability requirements
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  
  # CRITICAL: Instances must get public IPs to reach S3/SQS without a NAT Gateway
  map_public_ip_on_launch = true 

  tags = {
    Name    = "${var.project_name}-public-subnet-${count.index + 1}"
    Project = var.project_name
    Tier    = "Public"
  }
}

# --- 4. Route Table ---
# Directs traffic from subnets to the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "${var.project_name}-public-rt-${var.environment}"
    Project = var.project_name
  }
}

# --- 5. Route Table Association ---
# Binds the subnets to the Route Table
resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}