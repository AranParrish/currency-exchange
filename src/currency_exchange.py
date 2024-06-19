import requests
from requests import HTTPError
import json

API_MAIN_SOURCE = "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/gbp.json"
API_FALLBACK_SOURCE = "https://latest.currency-api.pages.dev/v1/currencies/gbp.json"


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
        return currency_rates

    elif api_response.status_code == 500:

        fallback_response = requests.get(API_FALLBACK_SOURCE)
        if fallback_response.status_code == 200:

            currency_rates = json.loads(fallback_response.text)
            return currency_rates

        elif fallback_response.status_code == 500:
            raise HTTPError("Servers busy, try again later")


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
                err_text = f"{currency} is not a valid currency code"
                raise KeyError(err_text)

        return currencies

    else:
        raise TypeError("Invalid input format")


def load_currency_rates(transformed_data: dict):
    pass
