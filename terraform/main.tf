# ==============================================================================
# AWS NETWORKING INFRASTRUCTURE (VPC & SUBNETS)
# ==============================================================================
# Creates an isolated Virtual Private Cloud (VPC) network in AWS.
# ==============================================================================

# Create a VPC network block
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16" # Network address range (65,536 IPs)
  enable_dns_hostnames = true          # Required for RDS and public EC2 DNS names
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

# Create an Internet Gateway (IGW) to allow internet ingress/egress
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# Create a Public Subnet for the EC2 App Host
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24" # Range of 256 IPs
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true # Automatically assigns a public IP to EC2 instances

  tags = {
    Name = "${var.environment}-public-subnet"
  }
}

# AWS RDS instances require at least two subnets in different Availability Zones (AZs)
# for high-availability subnet group configurations.

# Create Private Subnet A for RDS
resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.environment}-private-subnet-a"
  }
}

# Create Private Subnet B for RDS
resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "${var.environment}-private-subnet-b"
  }
}

# Create a public Route Table mapping subnet traffic out to the Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # Targets all external internet addresses
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

# Associate Route Table with Public Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ==============================================================================
# SECURITY GROUPS (FIREWALL RULES)
# ==============================================================================
# Defines stateful firewall rules to control traffic flow.
# ==============================================================================

# EC2 Web App Security Group
resource "aws_security_group" "web_sg" {
  name        = "${var.environment}-web-sg"
  description = "Allows HTTP, HTTPS, and SSH traffic to EC2"
  vpc_id      = aws_vpc.main.id

  # Ingress: Incoming traffic rules
  ingress {
    description = "HTTP Inbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to public internet
  }

  ingress {
    description = "HTTPS Inbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to public internet
  }

  ingress {
    description = "SSH Inbound"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change this to your office/home IP in production for security!
  }

  # Egress: Outgoing traffic rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allows all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-web-sg"
  }
}

# RDS Database Security Group
resource "aws_security_group" "db_sg" {
  name        = "${var.environment}-db-sg"
  description = "Allows database connection ONLY from the EC2 web server"
  vpc_id      = aws_vpc.main.id

  # Security Best Practice: Only allow Postgres traffic coming from the EC2 security group
  ingress {
    description     = "PostgreSQL Inbound from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id] # Source limited to EC2 instance group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-db-sg"
  }
}

# ==============================================================================
# DATABASE SERVICE (RDS POSTGRES INSTANCE)
# ==============================================================================

# RDS Subnet Group joins multiple subnet zones together
resource "aws_db_subnet_group" "db_subnets" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

# Create RDS Postgres instance
resource "aws_db_instance" "postgres" {
  identifier             = "${var.environment}-postgres"
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.t3.micro" # Free-tier eligible size
  allocated_storage      = 20            # 20 Gigabytes of storage
  max_allocated_storage  = 100           # Auto-scales up to 100GB if needed
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true          # Speeds up deletion when destroying infrastructure for dev

  tags = {
    Name        = "${var.environment}-rds-postgres"
    Environment = var.environment
  }
}

# ==============================================================================
# COMPUTE LAYER (EC2 VIRTUAL MACHINE HOST)
# ==============================================================================

# Fetch the latest Ubuntu Server AMI (Amazon Machine Image) ID dynamically
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical owner ID for Ubuntu

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Create EC2 virtual host instance
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # User Data: Script run once on instance startup to bootstrap Docker
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io git
              systemctl start docker
              systemctl enable docker
              # Add ubuntu user to docker group to run docker commands without sudo
              usermod -aG docker ubuntu
              EOF

  tags = {
    Name        = "${var.environment}-app-server"
    Environment = var.environment
  }
}
