import pytest
from requests import HTTPError
from src.currency_exchange import extract_currency_rates, transform_currency_rates, \
    load_currency_rates

@pytest.mark.describe('Extract currency rates tests')
class TestExtract:

    @pytest.mark.it('Returns gbp currency rates dict')
    def test_extract_given_currency_rates(self):
        test_currency = 'gbp'
        output = extract_currency_rates(test_currency)
        assert isinstance(output['gbp'], dict)
        assert isinstance(output['gbp']['eur'], float)

    @pytest.mark.it('Raises error for invalid currency')
    def test_extract_invalid_currency(self):
        invalid_currency = 'gbbp'
        with pytest.raises(HTTPError) as e:
            extract_currency_rates(invalid_currency)
        assert "base currency in shorthand format" in str(e.value)

    @pytest.mark.it('Function is case insensitive')
    def test_extract_case_insensitive(self):
        test_currency = 'GBP'
        output = extract_currency_rates(test_currency)
        assert isinstance(output['gbp'], dict)
        assert isinstance(output['gbp']['eur'], float)