import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context) -> dict:
    """Transform currency exchange rate data to give rate and reverse rate.

    Transforms the inputted currency exchange rate data to provide the user with rate and
    reverse rate values against the base currency of GBP.  By default, provides just EUR
    and USD rates, but can optionally take a list of currencies to return.

    Args:
        currency_rates: GBP exchange rate source data
        (optional) currencies_list: List of currency rates to be returned, defaults to EUR and USD.

    Returns:
        A dictionary providing the rate and reverse rate against GBP for the specified currencies.

    Error logs:
        Invalid input is not of the expected type
        Currency not valid if any currency in currencies_list not found in the extracted_data
    """
    currencies = {}
    if isinstance(event["currency_rates"], dict) and isinstance(
        event["currencies_list"], list
    ):

        for currency in event["currencies_list"]:
            try:
                currencies[currency] = {
                    "rate": event["currency_rates"]["gbp"][currency],
                    "reverse_rate": 1 / event["currency_rates"]["gbp"][currency],
                }
            except KeyError:
                logger.error(f"{currency} is not a valid currency code")

        logger.info("Successfully generated rate and reverse rate")
        return currencies

    else:
        logger.error("Invalid input format")
