## Defines IAM roles and attaches necessary policies for MWAA

# Get the current account identity and region
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Get default MWAA assume role info
data "aws_iam_policy_document" "mwaa_assume_role" {
    statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["airflow.amazonaws.com","airflow-env.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Create MWAA execution role and assume default policy
resource "aws_iam_role" "mwaa_execution_role" {
  name               = "mwaa-execution-role"
  assume_role_policy = data.aws_iam_policy_document.mwaa_assume_role.json
}

# Create Airflow metrics policy document and attach to MWAA role
data "aws_iam_policy_document" "airflow_metrics" {
  statement {
    effect = "Allow"
    actions = [
      "airflow:PublishMetrics",
      "cloudwatch:PutMetricData"
    ]
    resources = ["*"]
  }
}

# Create Airflow metrics policy
resource "aws_iam_policy" "airflow_metrics" {
  name   = "MWAA-AirflowMetrics-Policy"
  policy = data.aws_iam_policy_document.airflow_metrics.json
}

# Attach Airflow metrics policy to MWAA execution role
resource "aws_iam_role_policy_attachment" "airflow_metrics" {
  role       = aws_iam_role.mwaa_execution_role.name
  policy_arn = aws_iam_policy.airflow_metrics.arn
}

# Create MWAA S3 access policy document
data "aws_iam_policy_document" "mwaa_s3_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject*",
      "s3:GetBucket*",
      "s3:List*",
      "s3:PutObject"
    ]
    resources = [
        "arn:aws:s3:::${aws_s3_bucket.dag_s3.bucket}",
        "arn:aws:s3:::${aws_s3_bucket.dag_s3.bucket}/*",
        "arn:aws:s3:::${aws_s3_bucket.ce_s3.bucket}",
        "arn:aws:s3:::${aws_s3_bucket.ce_s3.bucket}/*",
        ]
  }
}

# Create MWAA S3 access policy
resource "aws_iam_policy" "mwaa_s3_policy" {
  name   = "MWAA-S3Access-Policy"
  policy = data.aws_iam_policy_document.mwaa_s3_access.json
}

# Attach MWAA S3 access policy to MWAA execution role
resource "aws_iam_role_policy_attachment" "mwaa_s3_policy_attach" {
  role       = aws_iam_role.mwaa_execution_role.name
  policy_arn = aws_iam_policy.mwaa_s3_policy.arn
}

# Create MWAA SQS access policy document
data "aws_iam_policy_document" "mwaa_sqs_access" {
  statement {
    effect = "Allow"
    actions = [
        "sqs:ChangeMessageVisibility",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ReceiveMessage",
        "sqs:SendMessage"
    ]
    resources = [
        "arn:aws:sqs:${data.aws_region.current.name}:*:airflow-celery-*"
        ]
  }
}

# Create MWAA SQS access policy
resource "aws_iam_policy" "mwaa_sqs_policy" {
  name   = "MWAA-SQSAccess-Policy"
  policy = data.aws_iam_policy_document.mwaa_sqs_access.json
}

# Attach MWAA SQS access policy to MWAA execution role
resource "aws_iam_role_policy_attachment" "mwaa_sqs_policy_attach" {
  role       = aws_iam_role.mwaa_execution_role.name
  policy_arn = aws_iam_policy.mwaa_sqs_policy.arn
}

# Create MWAA KMS access policy document
data "aws_iam_policy_document" "mwaa_kms_access" {
  statement {
    effect = "Allow"
    actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey*",
        "kms:Encrypt"
    ]
    resources = [ 
        "*",
     ]
    }
}

# Create MWAA KMS access policy
resource "aws_iam_policy" "mwaa_kms_policy" {
  name   = "MWAA-KMSAccess-Policy"
  policy = data.aws_iam_policy_document.mwaa_kms_access.json
}

# Attach MWAA KMS access policy to MWAA execution role
resource "aws_iam_role_policy_attachment" "mwaa_kms_policy_attach" {
  role       = aws_iam_role.mwaa_execution_role.name
  policy_arn = aws_iam_policy.mwaa_kms_policy.arn
}

# Create IAM policy inline for CloudWatch Logs permissions
resource "aws_iam_policy" "mwaa_cloudwatch_logs_policy" {
  name        = "MwaaCloudWatchLogsPermissions"
  description = "IAM policy for MWAA Logs permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:GetLogRecord",
          "logs:GetLogGroupFields",
          "logs:GetQueryResults",
        ]
      Resource = [
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:airflow-${var.mwaa_name}-*"
      ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
        ]
        Resource = [
          "*"
        ]
      }
    ]
  })
}

# Attach CloudWatch Logs policy to the MWAA execution role
resource "aws_iam_role_policy_attachment" "mwaa_cloudwatch_logs_attach" {
  role       = aws_iam_role.mwaa_execution_role.name
  policy_arn = aws_iam_policy.mwaa_cloudwatch_logs_policy.arn
}
