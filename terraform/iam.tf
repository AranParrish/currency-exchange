## Defines IAM roles and attaches necessary policies for MWAA

# Get default MWAA assume role info
data "aws_iam_policy_document" "mwaa_assume_role" {
    statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["airflow.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# MWAA role and assume role policy
resource "aws_iam_role" "mwaa_execution_role" {
  name               = "mwaa-execution-role"
  assume_role_policy = data.aws_iam_policy_document.mwaa_assume_role.json
}

# Grant MWAA role full access persmission for S3 (to allow reading of DAG files and output of data)
resource "aws_iam_role_policy_attachment" "mwaa_s3_permissions" {
  role       = aws_iam_role.mwaa_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Attach CloudWatch Logs policy to the MWAA role
resource "aws_iam_role_policy_attachment" "extract_lambda_cloudwatch_logs_policy" {
  role       = aws_iam_role.mwaa_execution_role.name
  policy_arn = aws_iam_policy.mwaa_cloudwatch_logs_policy.arn
}