import json
import pytest
import requests
from unittest.mock import patch
from src.ce_extract_lambda import lambda_handler

# Sample mock response
mock_api_response = {
    "gbp": {
        "usd": 1.28,
        "eur": 1.17
    }
}

@patch("src.ce_extract_lambda.requests.get")
def test_lambda_handler_success(mock_get):
    mock_get.return_value.status_code = 200
    mock_get.return_value.text = json.dumps(mock_api_response)

    result = lambda_handler({}, {})
    assert result == mock_api_response
    assert "usd" in result["gbp"]
    assert "eur" in result["gbp"]

@patch("src.ce_extract_lambda.requests.get")
def test_lambda_handler_main_fails_then_fallback_succeeds(mock_get):
    # First call fails, second call succeeds
    mock_get.side_effect = [
        type("obj", (object,), {"status_code": 500}),
        type("obj", (object,), {"status_code": 200, "text": json.dumps(mock_api_response)})
    ]

    result = lambda_handler({}, {})
    assert result == mock_api_response

@pytest.mark.integration
def test_live_api_returns_data():
    result = lambda_handler({}, {})
    
    assert isinstance(result, dict)
    assert "gbp" in result
    assert isinstance(result["gbp"], dict)

@pytest.mark.integration
def test_live_api_contains_expected_currencies():
    result = lambda_handler({}, {})
    
    expected = ["usd", "eur", "cspr", "tzs", "hkd", "jpy"]
    for currency in expected:
        assert currency in result["gbp"]
        assert isinstance(result["gbp"][currency], (float, int))