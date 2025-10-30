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

# MWAA role and assume default policy

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

resource "aws_iam_policy" "airflow_metrics" {
  name   = "MWAA-AirflowMetrics-Policy"
  policy = data.aws_iam_policy_document.airflow_metrics.json
}

resource "aws_iam_role_policy_attachment" "airflow_metrics" {
  role       = aws_iam_role.mwaa_execution_role.name
  policy_arn = aws_iam_policy.airflow_metrics.arn
}

# Create MWAA S3 access policy document and attach to MWAA role

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
        "arn:aws:s3:::ap-gbp-exchange-rate-data",
        "arn:aws:s3:::ap-gbp-exchange-rate-data/*",
        ]
  }
}

resource "aws_iam_policy" "mwaa_s3_policy" {
  name   = "MWAA-S3Access-Policy"
  policy = data.aws_iam_policy_document.mwaa_s3_access.json
}

resource "aws_iam_role_policy_attachment" "mwaa_s3_policy_attach" {
  role       = aws_iam_role.mwaa_execution_role.name
  policy_arn = aws_iam_policy.mwaa_s3_policy.arn
}

# Create MWAA SQS access policy document and attach to MWAA role

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

resource "aws_iam_policy" "mwaa_sqs_policy" {
  name   = "MWAA-SQSAccess-Policy"
  policy = data.aws_iam_policy_document.mwaa_sqs_access.json
}

resource "aws_iam_role_policy_attachment" "mwaa_sqs_policy_attach" {
  role       = aws_iam_role.mwaa_execution_role.name
  policy_arn = aws_iam_policy.mwaa_sqs_policy.arn
}

# Create MWAA KMS access policy document and attach to MWAA role

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
        "*"
        # "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*",
        # "arn:aws:kms:*:aws:alias/aws/s3",
        # "arn:aws:kms:*:aws:alias/aws/sqs",
        # "arn:aws:kms:*:aws:alias/aws/logs",
        # "arn:aws:kms:*:aws:alias/aws/airflow",
     ]
    }
}

resource "aws_iam_policy" "mwaa_kms_policy" {
  name   = "MWAA-KMSAccess-Policy"
  policy = data.aws_iam_policy_document.mwaa_kms_access.json
}

resource "aws_iam_role_policy_attachment" "mwaa_kms_policy_attach" {
  role       = aws_iam_role.mwaa_execution_role.name
  policy_arn = aws_iam_policy.mwaa_kms_policy.arn
}

# Attach CloudWatch Logs policy to the MWAA role

resource "aws_iam_role_policy_attachment" "mwaa_cloudwatch_logs_attach" {
  role       = aws_iam_role.mwaa_execution_role.name
  policy_arn = aws_iam_policy.mwaa_cloudwatch_logs_policy.arn
}


# ## MWAA VPC Endpoint IAM Policies and Interface Endpoints

# locals {
#   mwaa_interface_endpoints = {
#     logs       = ["logs:CreateLogStream","logs:PutLogEvents","logs:DescribeLogGroups","logs:DescribeLogStreams"]
#     sqs        = ["sqs:SendMessage","sqs:ReceiveMessage","sqs:GetQueueAttributes","sqs:DeleteMessage","sqs:ChangeMessageVisibility","sqs:GetQueueUrl"]
#     kms        = ["kms:Decrypt","kms:Encrypt","kms:GenerateDataKey*","kms:DescribeKey"]
#     monitoring = ["cloudwatch:PutMetricData","cloudwatch:GetMetricData","cloudwatch:GetMetricStatistics","cloudwatch:ListMetrics"]
#     sts        = ["sts:AssumeRole","sts:GetCallerIdentity"]
#   }
# }

# # Create interface endpoints
# resource "aws_vpc_endpoint" "interface_endpoints" {
#   for_each = local.mwaa_interface_endpoints

#   vpc_id             = aws_vpc.mwaa_vpc.id
#   service_name       = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
#   vpc_endpoint_type  = "Interface"
#   subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
#   security_group_ids = [aws_security_group.mwaa_sg.id]
#   private_dns_enabled = true

#   # Dynamically generate the policy JSON for the endpoint
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = { AWS = [aws_iam_role.mwaa_execution_role.arn] },
#         Action = each.value,
#         Resource = "*"
#       }
#     ]
#   })

#   tags = {
#     Name = "mwaa-${each.key}-endpoint"
#   }
# }


# # S3 Gateway Endpoint Policy
# data "aws_iam_policy_document" "mwaa_s3_vpc_endpoint" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "s3:GetObject",
#       "s3:GetBucketLocation",
#       "s3:ListBucket",
#       "s3:PutObject"
#     ]
#     resources = [
#       aws_s3_bucket.dag_s3.arn,
#       "${aws_s3_bucket.dag_s3.arn}/*",
#       aws_s3_bucket.ce_s3.arn,
#       "${aws_s3_bucket.ce_s3.arn}/*"
#     ]
#     principals {
#       type        = "AWS"
#       identifiers = [aws_iam_role.mwaa_execution_role.arn]
#     }
#   }
# }

# # S3 Gateway VPC Endpoint
# resource "aws_vpc_endpoint" "s3" {
#   vpc_id            = aws_vpc.mwaa_vpc.id
#   service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
#   vpc_endpoint_type = "Gateway"
#   route_table_ids   = [
#     aws_route_table.private_rt_a.id,
#     aws_route_table.private_rt_b.id,
#     ]
#   policy            = data.aws_iam_policy_document.mwaa_s3_vpc_endpoint.json

#   tags = {
#     Name = "mwaa-s3-endpoint"
#   }
# }
