# Creates and configures S3 buckets

# Currency exchange data bucket

resource "aws_s3_bucket" "ce_s3" {
  bucket_prefix = "${var.s3_ce_data}-"

  tags = {
    Name        = "CurrencyExchangeS3"
    Environment = "Dev"
  }
}