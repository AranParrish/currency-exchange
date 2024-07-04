import pytest
from requests import HTTPError
from unittest.mock import Mock, patch
import boto3
from botocore.exceptions import ClientError
from moto import mock_aws
from os import environ
import logging
from src.currency_exchange import (
    extract_currency_rates,
    transform_currency_rates,
    load_currency_rates,
)


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
        "EUR": {"rate": 1.01, "reverse_rate": (1 / 1.01)},
        "USD": {"rate": 1.5, "reverse_rate": (1 / 1.5)},
    }


@pytest.mark.describe("Extract currency rates tests")
class TestExtract:

    @pytest.mark.it("Returns gbp currency rates dict")
    def test_extract_given_currency_rates(self):
        output = extract_currency_rates()
        assert isinstance(output["gbp"], dict)
        assert isinstance(output["gbp"]["eur"], float)

    @pytest.mark.it("Logs error if both servers busy")
    def test_extract_fallback_if_main_busy(self, caplog):
        with patch("src.currency_exchange.requests.get") as mock_request:
            mock_request.return_value.status_code = 500
            with caplog.at_level(logging.ERROR):
                extract_currency_rates()
            assert "Servers busy" in caplog.text


@pytest.mark.describe("Transform currency rates tests")
class TestTransform:

    @pytest.mark.it("Output ref is not input ref")
    def test_transform_output_not_input(self):
        test_data = extract_currency_rates()
        output = transform_currency_rates(test_data)
        assert output is not test_data

    @pytest.mark.it("Inputs not mutated")
    def test_transform_inputs_not_mutated(self):
        test_data = extract_currency_rates()
        copy_test_data = extract_currency_rates()
        user_currencies = ["btc", "eth"]
        copy_user_currencies = ["btc", "eth"]
        transform_currency_rates(test_data, user_currencies)
        assert test_data == copy_test_data
        assert user_currencies == copy_user_currencies

    @pytest.mark.it("Returns EUR and USD dictionaries by default")
    def test_transform_output_format(self):
        test_data = extract_currency_rates()
        output = transform_currency_rates(test_data)
        assert "eur" in output.keys()
        assert "usd" in output.keys()
        for currency in output.keys():
            assert isinstance(output[currency]["rate"], float)
            assert isinstance(output[currency]["reverse_rate"], float)

    @pytest.mark.it("Returns user defined currency rates")
    def test_transform_user_currencies(self):
        test_data = extract_currency_rates()
        user_currencies = ["btc", "eth"]
        output = transform_currency_rates(test_data, user_currencies)
        assert all([currency in output.keys() for currency in user_currencies])

    @pytest.mark.it("Logs error for invalid input data")
    def test_transform_invalid_input_data(self, caplog):
        invalid_test_data = ["gbp", ["eur", "usd"]]
        with caplog.at_level(logging.ERROR):
            transform_currency_rates(invalid_test_data)
        assert "Invalid input format" in caplog.text

    @pytest.mark.it("Logs error for invalid currencies list")
    def test_transform_invalid_currencies_list(self, caplog):
        test_data = extract_currency_rates()
        invalid_currencies_list = ("btc", "eth")
        with caplog.at_level(logging.ERROR):
            transform_currency_rates(test_data, invalid_currencies_list)
        assert "Invalid input format" in caplog.text

    @pytest.mark.it("Logs error for invalid currency")
    def test_transform_invalid_currency(self, caplog):
        test_data = extract_currency_rates()
        invalid_currency = ["usd", "eurr"]
        with caplog.at_level(logging.ERROR):
            transform_currency_rates(test_data, invalid_currency)
        assert f"{invalid_currency[1]} is not a valid currency code" in caplog.text


@pytest.mark.describe("Load currency rates tests")
class TestLoad:

    @pytest.mark.it("Input data is not mutated")
    def test_load_input_data_not_mutated(self, test_exchange_data, test_bucket):
        test_data = test_exchange_data
        copy_test_data = test_exchange_data
        load_currency_rates(test_data, s3_bucket="test_bucket")
        assert test_data == copy_test_data

    @pytest.mark.it("Loads data to S3 bucket")
    def test_load_data_in_s3_bucket(self, test_exchange_data, s3_client, test_bucket):
        load_currency_rates(test_exchange_data, s3_bucket="test_bucket")
        response = s3_client.list_objects_v2(Bucket="test_bucket")
        assert response["KeyCount"] == 1
        assert "EUR" in response["Contents"][0]["Key"]
        assert "USD" in response["Contents"][0]["Key"]

    @pytest.mark.it("Logs error if s3 bucket does not exist")
    def test_load_raises_clienterror(self, test_exchange_data, s3_client, caplog):
        with caplog.at_level(logging.ERROR):
            load_currency_rates(test_exchange_data, s3_bucket="test_bucket")
        assert "NoSuchBucket" in caplog.text

    @pytest.mark.it("Logs error if data input is not a dictionary")
    def test_load_raises_typeerror_invalid_input_data(self, test_bucket, caplog):
        invalid_input_data = []
        with caplog.at_level(logging.ERROR):
            load_currency_rates(invalid_input_data, s3_bucket="test_bucket")
        assert "Invalid input format" in caplog.text

    @pytest.mark.it("Raises TypeError if s3 bucket is not a string")
    def test_load_raises_typeerror_invalid_s3_bucket_format(
        self, test_exchange_data, test_bucket, caplog
    ):
        invalid_s3_bucket_format = []
        with caplog.at_level(logging.ERROR):
            load_currency_rates(test_exchange_data, s3_bucket=invalid_s3_bucket_format)
        assert "Invalid input format" in caplog.text
