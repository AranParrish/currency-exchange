# Creates and configures S3 buckets

# Currency exchange data bucket

resource "aws_s3_bucket" "ce_s3" {
  bucket_prefix = "${var.s3_ce_data}-"

  tags = {
    Name        = "CurrencyExchangeS3"
    Environment = "Dev"
  }
}


data "aws_iam_policy_document" "s3_policy_document" {
  statement {
    actions = [
      "s3:*",
      "s3-object-lambda:*",
    ]

    resources =  ["*"]
  }
}

resource "aws_iam_policy" "s3_policy" {
  name       = "s3_policy"
  policy    = data.aws_iam_policy_document.s3_policy_document.json
}