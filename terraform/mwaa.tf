# Creates MWAA with the DAG and requirements.txt uploaded to S3 bucket

resource "aws_mwaa_environment" "ce_airflow_env" {
  name                  = "${var.mwaa_name}"
  execution_role_arn    = aws_iam_role.mwaa_execution_role.arn
  source_bucket_arn     = aws_s3_bucket.dag_s3.arn
  airflow_version       = "3.0.6"     # Available version for MWAA matched to Python 3.12
  environment_class     = "mw1.micro"
  webserver_access_mode = "PUBLIC_ONLY"
  
  dag_s3_path           = "dags"
  requirements_s3_path = aws_s3_object.reqs.key
  requirements_s3_object_version = aws_s3_object.reqs.version_id
#   startup_script_s3_path = aws_s3_object.startup_script.key
#   startup_script_s3_object_version = aws_s3_object.startup_script.version_id

  network_configuration {
    security_group_ids = [aws_security_group.mwaa_sg.id]
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  }
  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = "INFO"
    }
    scheduler_logs {
      enabled   = true
      log_level = "INFO"
    }
    task_logs {
      enabled   = true
      log_level = "INFO"
    }
    webserver_logs {
      enabled   = true
      log_level = "INFO"
    }
    worker_logs {
      enabled   = true
      log_level = "INFO"
    }
  }

  airflow_configuration_options = {
    "core.load_examples" = "False"
  }

  depends_on = [
    # aws_s3_object.startup_script,
    aws_s3_bucket.dag_s3,
    aws_s3_object.reqs,
    aws_s3_object.ce_dag,
    aws_iam_role.mwaa_execution_role,
    aws_nat_gateway.nat_gw_a,
    aws_nat_gateway.nat_gw_b,
    aws_route_table.private_rt_a,
    aws_route_table.private_rt_b,
    ]

}

## Networking requirements for MWAA (VPC, private subnets, public NAT access for private subnets, security group)

# Create VPC for MWAA
resource "aws_vpc" "mwaa_vpc" {
  cidr_block            = "10.0.0.0/16"
  enable_dns_support    = true
  enable_dns_hostnames  = true
  tags = {
    Name = "${var.mwaa_name} VPC"
  }
}

# Create first private subnet in eu-west-2a region
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.mwaa_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.mwaa_name} private subnet (AZ1)"
  }
}

# Create second private subnet in eu-west-2b region
resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.mwaa_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.mwaa_name} private subnet (AZ2)"
  }
}

# Route table for first private subnet
resource "aws_route_table" "private_rt_a" {
  vpc_id = aws_vpc.mwaa_vpc.id
  tags = {
    Name = "${var.mwaa_name} private routes (AZ1)"
  }
}

# Define route for first private subnet through nat gateway on eu-west-2a region
resource "aws_route" "private_internet_access_a" {
  route_table_id         = aws_route_table.private_rt_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw_a.id
  depends_on = [ 
    aws_nat_gateway.nat_gw_a
   ]
}

# Associate first private subnet with first private route table
resource "aws_route_table_association" "private_a_assoc" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt_a.id
}

# Route table for second private subnet
resource "aws_route_table" "private_rt_b" {
  vpc_id = aws_vpc.mwaa_vpc.id
  tags = {
    Name = "${var.mwaa_name} private routes (AZ2)"
  }
}

# Define route for second private subnet through nat gateway on eu-west-2b region
resource "aws_route" "private_internet_access_b" {
  route_table_id         = aws_route_table.private_rt_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw_b.id
  depends_on = [ 
    aws_nat_gateway.nat_gw_b
   ]
}

# Associate second private subnet with second private route table
resource "aws_route_table_association" "private_b_assoc" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt_b.id
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.mwaa_vpc.id
  tags = {
    Name = "${var.mwaa_name} IGW"
  }
}

# Create first public subnet in region eu-west-2a
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.mwaa_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.mwaa_name} public subnet (AZ1)"
  }
}

# Elastic IP for the first NAT Gateway
resource "aws_eip" "nat_eip_a" {
  domain = "vpc"
  tags = {
    Name = "${var.mwaa_name} EIP (AZ1)"
  }
}

# Create NAT Gateway in first public subnet
resource "aws_nat_gateway" "nat_gw_a" {
  allocation_id = aws_eip.nat_eip_a.id
  subnet_id     = aws_subnet.public_a.id
  depends_on = [ 
    aws_internet_gateway.igw
   ]
}

# Create second public subnet in region eu-west-2b
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.mwaa_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.mwaa_name} public subnet (AZ2)"
  }
}

# Elastic IP for the second NAT Gateway
resource "aws_eip" "nat_eip_b" {
  domain = "vpc"
  tags = {
    Name = "${var.mwaa_name} EIP (AZ2)"
  }
}

# Second NAT Gateway in public subnet B
resource "aws_nat_gateway" "nat_gw_b" {
  allocation_id = aws_eip.nat_eip_b.id
  subnet_id     = aws_subnet.public_b.id
  depends_on = [
    aws_internet_gateway.igw
  ]
}

# Public route table for NAT Gateway subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.mwaa_vpc.id
  tags = {
    Name = "${var.mwaa_name} public routes"
  }
}

# Create route table for public subnets to access internet
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate first public subnet with internet access route table
resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

# Associate second public subnet with internet access route table
resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

# Create security group with self-referencing rules to allow all internal traffic and external internet access for other AWS services
resource "aws_security_group" "mwaa_sg" {
  vpc_id = aws_vpc.mwaa_vpc.id
  tags = {
    Name = "${var.mwaa_name} SG"
  }

  ingress {
    description = "Allow all inbound traffic within MWAA"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description = "Allow all outbound traffic within MWAA"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}