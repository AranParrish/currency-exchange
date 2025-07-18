# Defines IAM roles and attaches necessary policies for lambda functions and step function

# # Step function role and assume role policy
# resource "aws_iam_role" "step_function_role" {
#   name_prefix = "role-${var.step_function_name}"
#   assume_role_policy = <<EOF
#   {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Action": "sts:AssumeRole",
#             "Principal": {
#                 "Service": "states.amazonaws.com"
#             }
#         }
#     ]
#   }
#   EOF
# }

# Extract lambda role and assume role policy
resource "aws_iam_role" "extract_lambda_role" {
    
    name_prefix = "role-${var.extract_lambda_name}"
    assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "sts:AssumeRole"
                ],
                "Principal": {
                    "Service": [
                        "lambda.amazonaws.com"
                    ]
                }
            }
        ]
    }
    EOF
}

# Attach CloudWatch Logs policy to the extract_lambda role
resource "aws_iam_role_policy_attachment" "extract_lambda_cloudwatch_logs_policy" {
  role       = aws_iam_role.extract_lambda_role.name
  policy_arn = aws_iam_policy.extract_cloudwatch_logs_policy.arn
}

# Transform lambda role and assume role policy

resource "aws_iam_role" "transform_lambda_role" {
    
    name_prefix = "role-${var.transform_lambda_name}"
    assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "sts:AssumeRole"
                ],
                "Principal": {
                    "Service": [
                        "lambda.amazonaws.com"
                    ]
                }
            }
        ]
    }
    EOF
}

# Attach CloudWatch Logs policy to the processed_lambda role
resource "aws_iam_role_policy_attachment" "transform_lambda_cloudwatch_logs_policy" {
  role       = aws_iam_role.transform_lambda_role.name
  policy_arn = aws_iam_policy.transform_cloudwatch_logs_policy.arn
}

# Load lambda role and assume role policy
resource "aws_iam_role" "load_lambda_role" {
    
    name_prefix = "role-${var.load_lambda_name}"
    assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "sts:AssumeRole"
                ],
                "Principal": {
                    "Service": [
                        "lambda.amazonaws.com"
                    ]
                }
            }
        ]
    }
    EOF
}

# Create S3 policy document for allowing access by a lambda function
data "aws_iam_policy_document" "s3_policy_document" {
  statement {
    actions = [
      "s3:*",
      "s3-object-lambda:*",
    ]

    resources =  ["*"]
  }
}


# Create S3 policy to be attached to lambda function role
resource "aws_iam_policy" "s3_policy" {
  name       = "s3_policy"
  policy    = data.aws_iam_policy_document.s3_policy_document.json
}

# Attach S3 policy to lambda function role for load lambda policy
resource "aws_iam_role_policy_attachment" "load_lambda_s3_policy_attachment" {
    role = aws_iam_role.load_lambda_role.name
    policy_arn = aws_iam_policy.s3_policy.arn
}


# Attach CloudWatch Logs policy to the load lambda role
resource "aws_iam_role_policy_attachment" "load_lambda_cloudwatch_logs_policy" {
  role       = aws_iam_role.load_lambda_role.name
  policy_arn = aws_iam_policy.load_cloudwatch_logs_policy.arn
}


# # Create lambda policy document for allowing invocation by step function
# data "aws_iam_policy_document" "lambda_invocation_policy_document" {
#   statement {
#     actions = [
#         "lambda:InvokeFunction"
#     ]
#     resources = [
#         aws_lambda_function.extract_lambda.arn,
#         aws_lambda_function.load_lambda.arn,
#         aws_lambda_function.transform_lambda.arn
#     ]
#   }
# }

# # Create lambda policy to be attached to step function
# resource "aws_iam_policy" "lambda_invocation_policy" {
#   name = "lambda_invocation_policy"
#   policy = data.aws_iam_policy_document.lambda_invocation_policy_document.json
# }

# # Attach lambda invocation policy to step function role
# resource "aws_iam_role_policy_attachment" "step_function_lambda_invocation_policy" {
#   role = aws_iam_role.step_function_role.name
#   policy_arn = aws_iam_policy.lambda_invocation_policy.arn
# }