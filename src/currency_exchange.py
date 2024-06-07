import requests
from requests import HTTPError
import json

API_MAIN_SOURCE_PREFIX = (
    "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/"
)
API_FALLBACK_SOURCE_PREFIX = "https://latest.currency-api.pages.dev/v1/currencies/"


def extract_currency_rates(base_currency: str) -> dict:

    base_currency_insensitive = base_currency.lower()

    api_response = requests.get(
        f"{API_MAIN_SOURCE_PREFIX}{base_currency_insensitive}.json"
    )
    if api_response.status_code == 200:

        currency_rates = json.loads(api_response.text)
        return currency_rates

    elif api_response.status_code == 500:

        fallback_response = requests.get(
            f"{API_FALLBACK_SOURCE_PREFIX}{base_currency_insensitive}.json"
        )
        if fallback_response.status_code == 200:

            currency_rates = json.loads(fallback_response.text)
            return currency_rates

        elif fallback_response.status_code == 500:
            raise HTTPError("Servers busy, try again later")

    elif api_response.status_code == 404:
        raise HTTPError("Invalid input: Enter base currency in shorthand format")


def transform_currency_rates(extracted_data: dict) -> dict:
    pass


def load_currency_rates(transformed_data: dict):
    pass
