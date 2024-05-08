import requests
from requests import HTTPError
import json

def extract_currency_rates(base_currency: str) -> dict:
    
    base_currency = base_currency.lower()

    api_main_source = f'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/{base_currency}.json'
    api_fallback_source = f'https://latest.currency-api.pages.dev/v1/currencies/{base_currency}.json'

    api_response = requests.get(api_main_source)

    if api_response.status_code == 200:

        currency_rates = json.loads(api_response.text)
        return currency_rates
    
    elif api_response.status_code == 404:
        raise HTTPError('Invalid input: Enter base currency in shorthand format')

def transform_currency_rates(extracted_data: dict) -> dict:
    pass

def load_currency_rates(transformed_data: dict):
    pass