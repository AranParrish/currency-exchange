import requests
import json
import boto3
from datetime import date
from botocore.exceptions import ClientError
import logging

API_MAIN_SOURCE = "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/gbp.json"
API_FALLBACK_SOURCE = "https://latest.currency-api.pages.dev/v1/currencies/gbp.json"
DATA_BUCKET = "ap-gbp-exchange-rate-data"

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def extract_currency_rates() -> dict:
    """Extracts today's currency exchange rates for great british pounds (GBP).

    Extracts today's GBP currency rates using the provided API source,
    using the fallback API source if that is busy.

    Args:
        None

    Returns:
        A dictionary of currency rates against the base currency

    Raises:
        HTTPError if both servers busy
    """

    api_response = requests.get(API_MAIN_SOURCE)
    if api_response.status_code == 200:

        currency_rates = json.loads(api_response.text)
        logger.info(f"Extracted currency rates for {date.today()}")
        return currency_rates

    elif api_response.status_code == 500:

        fallback_response = requests.get(API_FALLBACK_SOURCE)
        if fallback_response.status_code == 200:

            currency_rates = json.loads(fallback_response.text)
            logger.info(f"Extracted currency rates for {date.today()}")
            return currency_rates

        elif fallback_response.status_code == 500:
            logger.error("Servers busy, try again later")


def transform_currency_rates(
    extracted_data: dict, currencies_list: list = ["eur", "usd"]
) -> dict:
    """Transform currency exchange rate data to give rate and reverse rate.

    Transforms the inputted currency exchange rate data to provide the user with rate and
    reverse rate values against the base currency of GBP.  By default, provides just EUR
    and USD rates, but can optionally take a list of currencies to return.

    Args:
        extracted_data: GBP exchange rate source data
        (optional) currencies_list: List of currency rates to be returned, defaults to EUR and USD.

    Returns:
        A dictionary providing the rate and reverse rate against GBP for the specified currencies.

    Raises:
        TypeError if either input is not of the expected type
        KeyError if any currency in currencies_list not found in the extracted_data
    """
    currencies = {}
    if isinstance(extracted_data, dict) and isinstance(currencies_list, list):

        for currency in currencies_list:
            try:
                currencies[currency] = {
                    "rate": extracted_data["gbp"][currency],
                    "reverse_rate": 1 / extracted_data["gbp"][currency],
                }
            except KeyError:
                logger.error(f"{currency} is not a valid currency code")

        logger.info("Successfully generated rate and reverse rate")
        return currencies

    else:
        logger.error("Invalid input format")


def load_currency_rates(transformed_data: dict, s3_bucket: str) -> None:
    """Load transformed currency exchange rate data into S3 bucket.

    Loads provided currency exchange rate data into the S3 data storage bucket created by Terraform.
    Uses date stamp to keep files identifiable for each day, allowing analytics for trends over time.

    Args:
        transformed_data: Dictionary of rate and reverse rate for select currencies against GBP
        s3_bucket: Name of the S3 bucket in which the exchange rate data is to be stored

    Returns:
        None.  Results are saved to an S3 bucket.

    Raises:
        TypeError if either input is not of the expected type.
        NoSuchBucket if input s3 bucket does not exist.
        ClientError if client connection fails.

    """
    if isinstance(transformed_data, dict) and isinstance(s3_bucket, str):
        file = json.dumps(transformed_data, default=str)
        key = f"{date.today()}"
        for currency in transformed_data.keys():
            key += f"-{currency}"
        key += ".json"

        try:
            s3_client = boto3.client("s3")
            s3_client.put_object(Bucket=s3_bucket, Key=key, Body=file)
            logger.info(f"Successfully loaded exchange rate info into {s3_bucket}")
        
        except ClientError as e:
            logger.error(e)

    else:
        logger.error("Invalid input format")
