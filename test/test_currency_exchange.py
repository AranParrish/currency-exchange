import pytest, boto3, json, logging, datetime
from unittest.mock import Mock, patch
from moto import mock_aws
from os import environ

from airflow.models import DagBag

with patch.dict(environ, {"ce_bucket": "test_bucket"}):
    from src.currency_exchange import (
        extract_currency_rates,
        transform_currency_rates,
        load_currency_rates,
    )


@pytest.fixture()
def dagbag():
    return DagBag()


@pytest.fixture()
def dag(dagbag):
    ce_dag = dagbag.get_dag(dag_id="currency_exchange_dag")
    return ce_dag


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
        "extracted_data": extract_currency_rates(),
        "currencies_list": ["eur", "usd"],
    }


@pytest.fixture(scope="function")
def test_load_event(test_transform_event):
    return transform_currency_rates(**test_transform_event)


@pytest.mark.describe("DAG tests")
class TestDag:

    @pytest.mark.it("DAG successfully loaded")
    def test_dag_loaded(self, dagbag):
        dag = dagbag.get_dag(dag_id="currency_exchange_dag")
        assert dagbag.import_errors == {}
        assert dag is not None
        assert len(dag.tasks) == 3

    @pytest.mark.it("DAG contains expected tasks")
    def test_dag_tasks(self, dag):
        dag_order_dict = {
            "extract_task": ["transform_task"],
            "transform_task": ["load_task"],
            "load_task": [],
        }
        assert dag.task_dict.keys() == dag_order_dict.keys()

    @pytest.mark.it("DAG tasks in expected order")
    def test_dag_tasks_order(self, dag):
        dag_order_dict = {
            "extract_task": ["transform_task"],
            "transform_task": ["load_task"],
            "load_task": [],
        }
        for task_id, downstream_list in dag_order_dict.items():
            assert dag.has_task(task_id)
            task = dag.get_task(task_id)
            assert task.downstream_task_ids == set(downstream_list)


@pytest.mark.describe("Extract currency rates tests")
class TestExtract:

    @pytest.mark.it("Returns gbp currency rates dict")
    def test_extract_given_currency_rates(self):
        output = extract_currency_rates()
        assert isinstance(output["gbp"], dict)
        assert isinstance(output["gbp"]["eur"], float)

    @pytest.mark.it("Logs error if both servers busy")
    def test_extract_fallback_if_main_busy(self, caplog):
        with patch("requests.get") as mock_request:
            mock_request.return_value.status_code = 500
            with caplog.at_level(logging.ERROR):
                extract_currency_rates()
            assert "Servers busy" in caplog.text

    @pytest.mark.it("Able to return rates from fallback API source")
    def test_fallback_api_source(self):
        mock_api_response = {"gbp": {"usd": 1.28, "eur": 1.17}}
        with patch("requests.get") as mock_request:
            mock_request.side_effect = [
                type("obj", (object,), {"status_code": 500}),
                type(
                    "obj",
                    (object,),
                    {"status_code": 200, "text": json.dumps(mock_api_response)},
                ),
            ]
            output = extract_currency_rates()
            assert output == mock_api_response


@pytest.mark.describe("Transform currency rates tests")
class TestTransform:

    @pytest.mark.it("Output ref is not input ref")
    def test_transform_output_not_input(self, test_transform_event):
        test_data = extract_currency_rates()
        output = transform_currency_rates(**test_transform_event)
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
    def test_transform_output_format(self, test_transform_event):
        output = transform_currency_rates(**test_transform_event)
        assert "eur" in output.keys()
        assert "usd" in output.keys()
        for currency in output.keys():
            assert isinstance(output[currency]["rate"], float)
            assert isinstance(output[currency]["reverse_rate"], float)

    @pytest.mark.it("Returns user defined currency rates")
    def test_transform_user_currencies(self, test_transform_event):
        user_currencies = ["btc", "eth"]
        output = transform_currency_rates(
            test_transform_event["extracted_data"], user_currencies
        )
        assert all([currency in output.keys() for currency in user_currencies])

    @pytest.mark.it("Logs error for invalid input type")
    def test_transform_invalid_input_data(self, test_transform_event, caplog):
        invalid_test_data = {"gbp", "eur", "usd"}
        with caplog.at_level(logging.ERROR):
            transform_currency_rates(
                test_transform_event["extracted_data"], invalid_test_data
            )
        assert "Invalid input format" in caplog.text

    @pytest.mark.it("Logs error for invalid currency")
    def test_transform_invalid_currency(self, test_transform_event, caplog):
        invalid_currency = ["usd", "eurr"]
        with caplog.at_level(logging.ERROR):
            transform_currency_rates(
                test_transform_event["extracted_data"], invalid_currency
            )
        assert f"{invalid_currency[1]} is not a valid currency code" in caplog.text


@pytest.mark.describe("Load currency rates tests")
class TestLoad:

    @pytest.mark.it("Input data is not mutated")
    def test_load_input_data_not_mutated(self, test_exchange_data, test_bucket):
        test_data = test_exchange_data
        copy_test_data = test_exchange_data
        load_currency_rates(test_data, "test_bucket")
        assert test_data == copy_test_data

    @pytest.mark.it("Loads data to S3 bucket")
    def test_load_data_in_s3_bucket(self, s3_client, test_load_event, test_bucket):
        load_currency_rates(test_load_event, "test_bucket")
        response = s3_client.list_objects_v2(Bucket="test_bucket")
        assert response["KeyCount"] == 1
        assert "eur" in response["Contents"][0]["Key"]
        assert "usd" in response["Contents"][0]["Key"]

    @pytest.mark.it("Logs error if s3 bucket does not exist")
    def test_load_raises_clienterror(self, test_load_event, s3_client, caplog):
        with caplog.at_level(logging.ERROR):
            load_currency_rates(test_load_event, "invalid_test_bucket")
        assert "NoSuchBucket" in caplog.text

    @pytest.mark.it("Logs error if data input is not a dictionary")
    def test_load_raises_typeerror_invalid_input_data(
        self, s3_client, test_bucket, caplog
    ):
        invalid_currencies_type = []
        with caplog.at_level(logging.ERROR):
            load_currency_rates(invalid_currencies_type, "test_bucket")
        assert "Invalid input format" in caplog.text
