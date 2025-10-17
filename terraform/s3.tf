## Creates and configures S3 buckets

# Currency exchange data bucket

resource "aws_s3_bucket" "ce_s3" {
  bucket_prefix = "${var.s3_ce_data}-"
  tags = {
    Name        = "CurrencyExchangeS3"
    Environment = "Dev"
  }
}

# Currency exchange DAG bucket

resource "aws_s3_bucket" "dag_s3" {
  bucket_prefix = "${var.s3_ce_dag_bucket}-"
  tags = {
    Name        = "CurrencyExchangeDAGS3"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "ce_dags_versioning" {
  bucket = aws_s3_bucket.dag_s3.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Upload DAG to DAG bucket

resource "aws_s3_object" "ce_dag" {
  bucket = aws_s3_bucket.dag_s3.id
  key = "dags/${var.ce_dag_filename}"
  source = "../src/${var.ce_dag_filename}"
}

# Upload requirements.txt to DAG bucket

resource "aws_s3_object" "reqs" {
  bucket = aws_s3_bucket.dag_s3.id
  key = "requirements.txt"
  source = "../requirements.txt"
}

# Upload startup script to DAG bucket for setting data bucket environment variable

resource "aws_s3_object" "startup_script" {
  bucket = aws_s3_bucket.dag_s3.id
  key = "startup/startup.sh"
  content = <<-EOT
    #!/bin/bash
    export ce_bucket=${aws_s3_bucket.ce_s3.bucket}
  EOT
}