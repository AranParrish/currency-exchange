# Defines variables used across the Terraform configurations

variable "s3_ce_data" {
    type = string
    default = "currency-exchange-bucket"
}

variable "extract_lambda_name" {
    type = string
    default = "ce-extract-lambda"
}

variable "transform_lambda_name" {
    type = string
    default = "ce-transform-lambda"
}

variable "load_lambda_name" {
    type = string
    default = "ce-load-lambda"
}