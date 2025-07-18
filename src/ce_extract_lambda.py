import requests
import json
from datetime import date
import logging

API_MAIN_SOURCE = "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/gbp.json"
API_FALLBACK_SOURCE = "https://latest.currency-api.pages.dev/v1/currencies/gbp.json"

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context) -> dict:
    """Extracts today's currency exchange rates for great british pounds (GBP).

    Extracts today's GBP currency rates using the provided API source,
    using the fallback API source if that is busy.

    Args:
        None

    Returns:
        A dictionary of currency rates against the base currency

    Error logs:
        Servers busy if unable to get data from either API source
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
