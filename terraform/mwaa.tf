########################
# Create MWAA resource #
########################

resource "aws_mwaa_environment" "ce_airflow_env" {
  name                  = "${var.mwaa_name}"
  execution_role_arn    = aws_iam_role.mwaa_execution_role.arn
  source_bucket_arn     = aws_s3_bucket.dag_s3.arn
  airflow_version       = "3.0.6"     # Available version for MWAA matched to Python 3.12
  environment_class     = "mw1.micro"
  webserver_access_mode = "PUBLIC_ONLY"
  
  dag_s3_path           = "dags"
  requirements_s3_path = aws_s3_object.reqs.key
  requirements_s3_object_version = aws_s3_object.reqs.version_id
  startup_script_s3_path = aws_s3_object.startup_script.key
  startup_script_s3_object_version = aws_s3_object.startup_script.version_id

  network_configuration {
    security_group_ids = [aws_security_group.mwaa_sg.id]
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  }
  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = "INFO"
    }
    scheduler_logs {
      enabled   = true
      log_level = "INFO"
    }
    task_logs {
      enabled   = true
      log_level = "INFO"
    }
    webserver_logs {
      enabled   = true
      log_level = "INFO"
    }
    worker_logs {
      enabled   = true
      log_level = "INFO"
    }
  }

  airflow_configuration_options = {
    "core.load_examples" = "False"
  }

  depends_on = [
    aws_s3_object.startup_script,
    aws_s3_bucket.dag_s3,
    aws_s3_object.reqs,
    aws_s3_object.ce_dag,
    aws_iam_role.mwaa_execution_role,
    aws_nat_gateway.nat_gw_a,
    aws_nat_gateway.nat_gw_b,
    aws_route_table.private_rt_a,
    aws_route_table.private_rt_b,
    ]

}
