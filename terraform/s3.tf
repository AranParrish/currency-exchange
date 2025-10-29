## Creates and configures S3 buckets

# Currency exchange data bucket

resource "aws_s3_bucket" "ce_s3" {
  bucket_prefix = "${var.s3_ce_data}-"
  tags = {
    Name        = "CurrencyExchangeS3"
    Environment = "Dev"
  }
  force_destroy = true
}

# resource "aws_s3_bucket_server_side_encryption_configuration" "mwaa_data_sse" {
#   bucket = aws_s3_bucket.ce_s3.id
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "aws:kms"
#       kms_master_key_id = "alias/aws/s3"
#     }
#   }
# }

resource "aws_s3_bucket_public_access_block" "data_s3_block" {
  bucket = aws_s3_bucket.ce_s3.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# Currency exchange DAG bucket

resource "aws_s3_bucket" "dag_s3" {
  bucket_prefix = "${var.s3_ce_dag_bucket}-"
  tags = {
    Name        = "CurrencyExchangeDAGS3"
    Environment = "Dev"
  }
  force_destroy = true
}

# resource "aws_s3_bucket_server_side_encryption_configuration" "mwaa_dag_sse" {
#   bucket = aws_s3_bucket.dag_s3.id
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "aws:kms"
#       kms_master_key_id = "alias/aws/s3"
#     }
#   }
# }

resource "aws_s3_bucket_versioning" "ce_dags_versioning" {
  bucket = aws_s3_bucket.dag_s3.id
  versioning_configuration {
    status = "Enabled"
  }
}

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
  lifecycle {
    ignore_changes = [ version_id ]
  }
}

# Upload requirements.txt to DAG bucket

resource "aws_s3_object" "reqs" {
  bucket = aws_s3_bucket.dag_s3.id
  key = "requirements/cloud_reqs.txt"
  source = "../requirements/cloud_reqs.txt"
  etag = filemd5("../requirements/cloud_reqs.txt")
  depends_on = [ 
    aws_s3_bucket_versioning.ce_dags_versioning,
    aws_s3_bucket_public_access_block.dag_s3_block
   ]
  lifecycle {
    ignore_changes = [ version_id ]
  }
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
    aws_s3_bucket_versioning.ce_dags_versioning
   ]
}