# Defines variables used across the Terraform configurations

variable "s3-backend" {
    description = "Name of S3 bucket to be used for storing Terraform statefile"
    type = string
    default = "ap-terraform-statefiles"
}

variable "ce_dag_filename" {
    description = "Name of file containing DAG for currency exchange script"
    type = string
    default = "currency_exchange.py"
}

variable "s3_ce_data" {
    description = "Name of S3 bucket where currency exchange rates are to be stored"
    type = string
    default = "currency-exchange-bucket"
}

variable "s3_ce_dag_bucket" {
    description = "Name of S3 bucket where DAG and requirements.txt files are to be stored"
    type = string
    default = "currency-exchange-dag-bucket"
}

variable "mwaa_name" {
    description = "Name of MWAA environment"
    type = string
    default = "ce-mwaa"
}