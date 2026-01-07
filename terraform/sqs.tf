# Create SQS queue for queuing Airflow tasks and ensure it uses AWS managed KMS key for encryption

resource "aws_sqs_queue" "mwaa_queue" {
  name                        = "airflow-celery-queue"
  visibility_timeout_seconds  = 300
  message_retention_seconds   = 86400
  receive_wait_time_seconds   = 10

  kms_master_key_id = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300

  tags = {
    Name = "mwaa-celery-queue"
  }
}
