# Creates MWAA with the DAG and requirements.txt uploaded to S3 bucket

resource "aws_mwaa_environment" "ce_airflow_env" {
  name                  = "ce-mwaa"
  execution_role_arn    = aws_iam_role.mwaa_execution_role.arn
  source_bucket_arn     = aws_s3_bucket.dag_s3.arn
  dag_s3_path           = "dags"
  airflow_version       = "3.0.6"     # MWAA version must match available Airflow version
  environment_class     = "mw1.small"
  max_workers           = 5
  min_workers           = 1
  schedulers            = 2
  webserver_access_mode = "PUBLIC_ONLY"

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

  startup_script_s3_path = aws_s3_object.startup_script.key
  startup_script_s3_object_version = aws_s3_object.startup_script.version_id

  network_configuration {
    security_group_ids = [aws_security_group.mwaa_sg.id]
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  }

  airflow_configuration_options = {
    "core.load_examples" = "False"
  }

  depends_on = [aws_s3_object.startup_script]
  
}

# VPC for MWAA

resource "aws_vpc" "mwaa_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.mwaa_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.mwaa_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false
}

resource "aws_security_group" "mwaa_sg" {
  vpc_id = aws_vpc.mwaa_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}