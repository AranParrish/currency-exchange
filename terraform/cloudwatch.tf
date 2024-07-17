# Defines IAM policies and CloudWatch log groups/streams to manage and monitor logs for Lambda functions and Step function

# Get the current account identity and region

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Create IAM policy for Cloudwatch Logs permissions for step function

# Create IAM policy for CloudWatch Logs permissions for extract lambda function
resource "aws_iam_policy" "extract_cloudwatch_logs_policy" {
  name        = "ExtractCloudWatchLogsPermissions"
  description = "IAM policy for extract lambda CloudWatch Logs permissions"

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
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.extract_lambda_name}:*"
      }
    ]
  })
}

# Create IAM policy for CloudWatch Logs permissions for transform lambda function
resource "aws_iam_policy" "transform_cloudwatch_logs_policy" {
  name        = "TransformCloudWatchLogsPermissions"
  description = "IAM policy for transform lambda CloudWatch Logs permissions"

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
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.transform_lambda_name}:*"
      }
    ]
  })
}

# Create IAM policy for CloudWatch Logs permissions for load lambda function
resource "aws_iam_policy" "load_cloudwatch_logs_policy" {
  name        = "LoadCloudWatchLogsPermissions"
  description = "IAM policy for load lambda CloudWatch Logs permissions"

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
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.load_lambda_name}:*"
      }
    ]
  })
}