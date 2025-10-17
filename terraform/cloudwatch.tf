# Defines IAM policies and CloudWatch log groups/streams to manage and monitor logs for Lambda functions and Step function

# Get the current account identity and region

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Create IAM policy for CloudWatch Logs permissions for MWAA service
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
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/airflow/*"
      }
    ]
  })
}