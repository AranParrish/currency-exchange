## Creates and configures S3 buckets and upload required Airflow files

#################################
# Currency exchange data bucket #
#################################

# Create data bucket
resource "aws_s3_bucket" "ce_s3" {
  bucket_prefix = "${var.s3_ce_data}-"
  tags = {
    Name        = "CurrencyExchangeS3"
    Environment = "Dev"
  }
  force_destroy = true
}

# Block general public access for data bucket, but allow IAM controlled access
resource "aws_s3_bucket_public_access_block" "data_s3_block" {
  bucket = aws_s3_bucket.ce_s3.id
  block_public_acls = true
  ignore_public_acls = true
  block_public_policy = false
  restrict_public_buckets = false
}

#################################
# Currency exchange DAG bucket ##
#################################

# Create DAG bucket
resource "aws_s3_bucket" "dag_s3" {
  bucket_prefix = "${var.s3_ce_dag_bucket}-"
  tags = {
    Name        = "CurrencyExchangeDAGS3"
    Environment = "Dev"
  }
  force_destroy = true
}

# Enable versioning for DAG bucket (required for MWAA)
resource "aws_s3_bucket_versioning" "ce_dags_versioning" {
  bucket = aws_s3_bucket.dag_s3.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block all public access on DAG bucket (required for MWAA)
resource "aws_s3_bucket_public_access_block" "dag_s3_block" {
  bucket = aws_s3_bucket.dag_s3.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# Upload DAG to DAG bucket
resource "aws_s3_object" "ce_dag" {
  bucket = aws_s3_bucket.dag_s3.id
  key = "dags/${var.ce_dag_filename}"
  source = "../src/${var.ce_dag_filename}"
  etag = filemd5("../src/${var.ce_dag_filename}")
  depends_on = [ 
    aws_s3_bucket_versioning.ce_dags_versioning,
    aws_s3_bucket_public_access_block.dag_s3_block
   ]
}

# Upload requirements.txt to DAG bucket
resource "aws_s3_object" "reqs" {
  bucket = aws_s3_bucket.dag_s3.id
  key = "cloud_reqs.txt"
  source = "../requirements/cloud_reqs.txt"
  etag = filemd5("../requirements/cloud_reqs.txt")
  depends_on = [ 
    aws_s3_bucket_versioning.ce_dags_versioning,
    aws_s3_bucket_public_access_block.dag_s3_block
   ]
}

# Upload startup script to DAG bucket for setting data bucket environment variable
resource "aws_s3_object" "startup_script" {
  bucket = aws_s3_bucket.dag_s3.id
  key = "startup/startup.sh"
  content = <<-EOT
    #!/bin/bash
    export ce_bucket="${aws_s3_bucket.ce_s3.bucket}"
  EOT
  depends_on = [ 
    aws_s3_bucket_versioning.ce_dags_versioning,
    aws_s3_bucket_public_access_block.dag_s3_block
   ]
}