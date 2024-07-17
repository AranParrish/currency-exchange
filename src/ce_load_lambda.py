import json
import boto3
from datetime import date
from botocore.exceptions import ClientError
import logging
import os

DATA_BUCKET = os.environ["ce_bucket"]

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context) -> None:
    """Load transformed currency exchange rate data into S3 bucket.

    Loads provided currency exchange rate data into the S3 data storage bucket created by Terraform.
    Uses date stamp to keep files identifiable for each day, allowing analytics for trends over time.

    Args:
        transformed_data: Dictionary of rate and reverse rate for select currencies against GBP
        s3_bucket: Name of the S3 bucket in which the exchange rate data is to be stored

    Returns:
        None.  Results are saved to an S3 bucket.

    Error logs:
        Invalid input if either input is not of the expected type.
        ClientError message if unable to put data in s3 bucket.

    """
    if isinstance(event[currencies], dict) and isinstance(DATA_BUCKET, str):
        file = json.dumps(event[currencies], default=str)
        key = f"{date.today()}"
        for currency in event[currencies].keys():
            key += f"-{currency}"
        key += ".json"

        try:
            s3_client = boto3.client("s3")
            s3_client.put_object(Bucket=DATA_BUCKET, Key=key, Body=file)
            logger.info(f"Successfully loaded exchange rate info into {DATA_BUCKET}")

        except ClientError as e:
            logger.error(e)

    else:
        logger.error("Invalid input format")