import pytest
from unittest.mock import Mock, patch
import boto3
from botocore.exceptions import ClientError
from moto import mock_aws
from os import environ
import logging

# from src.currency_exchange import (
#     extract_currency_rates,
#     transform_currency_rates,
#     load_currency_rates,
# )
from src.ce_extract_lambda import lambda_handler as extract_currency_rates
from src.ce_transform_lambda import lambda_handler as transform_currency_rates

with patch.dict(environ, {"ce_bucket": "test_bucket"}):
    from src.ce_load_lambda import lambda_handler as load_currency_rates


@pytest.fixture(scope="class")
def aws_credentials():
    environ["AWS_ACCESS_KEY_ID"] = "test"
    environ["AWS_SECRET_ACCESS_KEY"] = "test"
    environ["AWS_SECURITY_TOKEN"] = "test"
    environ["AWS_SESSION_TOKEN"] = "test"
    environ["AWS_DEFAULT_REGION"] = "eu-west-2"


@pytest.fixture(scope="function")
def s3_client(aws_credentials):
    with mock_aws():
        yield boto3.client("s3")


@pytest.fixture(scope="function")
def test_bucket(s3_client):
    s3_client.create_bucket(
        Bucket="test_bucket",
        CreateBucketConfiguration={"LocationConstraint": "eu-west-2"},
    )


@pytest.fixture(scope="function")
def test_exchange_data():
    return {
        "eur": {"rate": 1.01, "reverse_rate": (1 / 1.01)},
        "usd": {"rate": 1.5, "reverse_rate": (1 / 1.5)},
    }


@pytest.fixture(scope="function")
def test_transform_event():
    return {
        "currency_rates": extract_currency_rates(event="event", context="context"),
        "currencies_list": ["eur", "usd"],
    }


@pytest.fixture(scope="function")
def test_load_event(test_transform_event):
    return {
        "currencies": transform_currency_rates(
            event=test_transform_event, context="context"
        )
    }


@pytest.mark.describe("Extract currency rates tests")
class TestExtract:

    @pytest.mark.it("Returns gbp currency rates dict")
    def test_extract_given_currency_rates(self):
        output = extract_currency_rates(event="event", context="context")
        assert isinstance(output["gbp"], dict)
        assert isinstance(output["gbp"]["eur"], float)

    @pytest.mark.it("Logs error if both servers busy")
    def test_extract_fallback_if_main_busy(self, caplog):
        with patch("src.ce_extract_lambda.requests.get") as mock_request:
            mock_request.return_value.status_code = 500
            with caplog.at_level(logging.ERROR):
                extract_currency_rates(event="event", context="context")
            assert "Servers busy" in caplog.text


@pytest.mark.describe("Transform currency rates tests")
class TestTransform:

    @pytest.mark.it("Output ref is not input ref")
    def test_transform_output_not_input(self, test_transform_event):
        test_data = extract_currency_rates(event="event", context="context")
        output = transform_currency_rates(event=test_transform_event, context="context")
        assert output is not test_data

    @pytest.mark.it("Inputs not mutated")
    def test_transform_inputs_not_mutated(self):
        test_data = extract_currency_rates(event="event", context="context")
        copy_test_data = extract_currency_rates(event="event", context="context")
        user_currencies = ["btc", "eth"]
        copy_user_currencies = ["btc", "eth"]
        test_transform_event = {
            "currency_rates": test_data,
            "currencies_list": user_currencies,
        }
        transform_currency_rates(event=test_transform_event, context="context")
        assert test_data == copy_test_data
        assert user_currencies == copy_user_currencies

    @pytest.mark.it("Returns EUR and USD dictionaries by default")
    def test_transform_output_format(self, test_transform_event):
        output = transform_currency_rates(event=test_transform_event, context="context")
        assert "eur" in output.keys()
        assert "usd" in output.keys()
        for currency in output.keys():
            assert isinstance(output[currency]["rate"], float)
            assert isinstance(output[currency]["reverse_rate"], float)

    @pytest.mark.it("Returns user defined currency rates")
    def test_transform_user_currencies(self):
        user_currencies = ["btc", "eth"]
        test_event = {
            "currency_rates": extract_currency_rates(event="event", context="context"),
            "currencies_list": user_currencies,
        }
        output = transform_currency_rates(event=test_event, context="context")
        assert all([currency in output.keys() for currency in user_currencies])

    @pytest.mark.it("Logs error for invalid input type")
    def test_transform_invalid_input_data(self, caplog):
        invalid_test_data = {"gbp", "eur", "usd"}
        test_event = {
            "currency_rates": extract_currency_rates(event="event", context="context"),
            "currencies_list": invalid_test_data,
        }
        with caplog.at_level(logging.ERROR):
            transform_currency_rates(event=test_event, context="context")
        assert "Invalid input format" in caplog.text

    @pytest.mark.it("Logs error for invalid currency")
    def test_transform_invalid_currency(self, caplog):
        invalid_currency = ["usd", "eurr"]
        test_event = {
            "currency_rates": extract_currency_rates(event="event", context="context"),
            "currencies_list": invalid_currency,
        }
        with caplog.at_level(logging.ERROR):
            transform_currency_rates(event=test_event, context="context")
        assert f"{invalid_currency[1]} is not a valid currency code" in caplog.text


@pytest.mark.describe("Load currency rates tests")
class TestLoad:

    @pytest.mark.it("Input data is not mutated")
    def test_load_input_data_not_mutated(
        self, test_exchange_data, test_load_event, test_bucket
    ):
        test_data = test_exchange_data
        copy_test_data = test_exchange_data
        load_currency_rates(event=test_load_event, context="context")
        assert test_data == copy_test_data

    @pytest.mark.it("Loads data to S3 bucket")
    def test_load_data_in_s3_bucket(self, s3_client, test_load_event, test_bucket):
        load_currency_rates(event=test_load_event, context="context")
        response = s3_client.list_objects_v2(Bucket="test_bucket")
        assert response["KeyCount"] == 1
        assert "eur" in response["Contents"][0]["Key"]
        assert "usd" in response["Contents"][0]["Key"]

    @pytest.mark.it("Logs error if s3 bucket does not exist")
    def test_load_raises_clienterror(self, test_load_event, s3_client, caplog):
        with caplog.at_level(logging.ERROR):
            load_currency_rates(event=test_load_event, context="context")
        assert "NoSuchBucket" in caplog.text

    @pytest.mark.it("Logs error if data input is not a dictionary")
    def test_load_raises_typeerror_invalid_input_data(
        self, s3_client, test_bucket, caplog
    ):
        invalid_test_load_event = {"currencies": []}
        with caplog.at_level(logging.ERROR):
            load_currency_rates(event=invalid_test_load_event, context="context")
        assert "Invalid input format" in caplog.text
