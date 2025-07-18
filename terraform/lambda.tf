# Creates and configures the Lambda functions and their dependencies

# Creates and configures extract lambda function
resource "aws_lambda_function" "extract_lambda" {
    function_name = "${var.extract_lambda_name}"
    role = aws_iam_role.extract_lambda_role.arn
    filename=data.archive_file.extract_lambda_zip.output_path
    source_code_hash = data.archive_file.extract_lambda_zip.output_base64sha256
    # layers = [aws_lambda_layer_version.extract_layer.arn]
    handler = "ce_extract_lambda.lambda_handler"
    runtime = "python3.12"
    timeout = 60

# Add dependency for cloudwatch access
    depends_on = [
    aws_iam_role_policy_attachment.extract_lambda_cloudwatch_logs_policy
  ]
}

# Manages Lambda layers to include dependencies
# resource "aws_lambda_layer_version" "extract_layer" {
#   layer_name = "extract_layer"
#   filename = data.archive_file.layer.output_path
  
# }

data "archive_file" "extract_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/ce_extract_lambda.py"
  output_path = "${path.module}/../src/ce_extract_lambda.zip"
}

# data "archive_file" "extract_layer" {
#   type = "zip"
#   source_dir = "${path.module}/../extract_layer/"
#   output_path = "${path.module}/../extract_layer.zip"
# }

# Creates and configures the transform lambda function

resource "aws_lambda_function" "transform_lambda" {
    function_name = "${var.transform_lambda_name}"
    role = aws_iam_role.transform_lambda_role.arn 
    filename=data.archive_file.transform_lambda_zip.output_path
    source_code_hash = data.archive_file.transform_lambda_zip.output_base64sha256
    # layers = ["arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python312:8"]
    handler = "ce_transform_lambda.lambda_handler" 
    runtime = "python3.12"
    timeout = 60

# Add dependencies for cloudwatch access
    depends_on = [
    aws_iam_role_policy_attachment.transform_lambda_cloudwatch_logs_policy
  ]
}

data "archive_file" "transform_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/ce_transform_lambda.py"
  output_path = "${path.module}/../src/ce_transform_lambda.zip"
}

# Creates and configures the load lambda functions

resource "aws_lambda_function" "load_lambda" {
    function_name = "${var.load_lambda_name}"
    role = aws_iam_role.load_lambda_role.arn 
    filename=data.archive_file.load_lambda_zip.output_path 
    source_code_hash = data.archive_file.load_lambda_zip.output_base64sha256
    # layers = ["arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python312:8", aws_lambda_layer_version.python_dotenv_layer.arn]
    handler = "ce_load_lambda.lambda_handler" 
    runtime = "python3.12"
    timeout = 60

# Add dependencies for load lambda s3 access and cloudwatch access
    depends_on = [
    aws_iam_role_policy_attachment.load_lambda_s3_policy_attachment,
    aws_iam_role_policy_attachment.load_lambda_cloudwatch_logs_policy
  ]

# Environment variable containing currency exchange S3 bucket name
  environment {
    variables = {
      ce_bucket = resource.aws_s3_bucket.ce_s3.bucket
    }
  }
}


data "archive_file" "load_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/ce_load_lambda.py"
  output_path = "${path.module}/../src/ce_load_lambda.zip"
}