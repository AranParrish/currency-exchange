# Currency Exchange (MWAA)

## Overview
This project automates the collection of daily exchange rate data (e.g. for trend analysis) for GBP against selected currencies (default of USD and EUR). It includes:
- **Python code** to fetch and process currency data.
- **Terraform scripts** to deploy the workflow to **AWS Managed Workflows for Apache Airflow (MWAA)**.
- **Makefile** and **python tests** for automation and validation.

The purpose of this repository is to demonstrate how to orchestrate data workflows using Apache Airflow in the cloud (AWS MWAA service). By default, exchange rate data is extracted daily at 1am GMT, transformed into rate and reverse rate values for each currency, and loaded in JSON format into an S3 bucket.

Pair programmed project developed using Agile methodologies by [Aran Parrish](https://github.com/AranParrish) and [Michael Lee](https://github.com/15ML).

Exchange rate data extracted via API using HTTP methods from [Free Currency Exchange Rates API](https://github.com/fawazahmed0/exchange-api). Includes a fallback source for robustness.

---

## Prerequisites
Before you begin, ensure you have the following installed and configured globally:

- **Make** (search online for installation instructions relevant to your operating system)
- **Python 3.12**

You should also have a basic understanding of orchestration with Apache Airflow.

---

## Getting Started
Fork and clone the repository to your local directory and cd into the root directory:

```sh
git clone https://github.com/AranParrish/currency-exchange.git
cd currency-exchange
```

---

## Folder Structure

The below block gives an overview of the repo folder structure.

```bash
currency-exchange/
│
├── src/            # Python source code
├── terraform/      # Infrastructure as Code for deploying as AWS MWAA service
├── test/           # Python test suite (>95% coverage)
├── requirements/   # Python dependencies for local and cloud builds
├── Makefile        # Helper commands for setting up local and/or cloud builds
└── Dockerfile      # Dockerfile for setting up local runtime environment
```
---

## Local Developer Environment


To setup your local developer environment, run the below command:

```sh
make local-requirements
```

This will create a virtual environment named "venv" on your local machine and install the required dependencies.

To run the test suite against the provided source code, run the below command:

```sh
make run-checks
```

This will run a security check (using bandit), automatically amend python files in the "src" and "test" folders to be PEP8 compliant (using black), run the unit tests (using pytest with testdox extension), and finally provided a test coverage report (which should yield >95% for the provided source code and test suite).

Any further developments to the source code should be appropriately tested.

---

## Cloud Deployment

In addition to the prerequisities, you will need the following installed and configured globally:
- **AWS Account**
- **AWS CLI** (configured with sufficient permissions to create MWAA and its dependencies, S3, and IAM resources)
- **Terraform**

Deployment steps:
1. Either create a new S3 bucket or select an existing S3 bucket to be used to store the Terraform statefile for this project.
2. Navigate into the terraform directory (i.e. do "cd terraform" in the command line).
3. You will then need to edit the file "vars.tf" to at least ensure the Terraform variable "s3-backend" is set to the name of your selected S3 bucket.
4. (Optional) - amend other values in the "vars.tf" file as appropriate for your deployment.
5. Ensure all changes to "vars.tf" are saved and committed to your forked repo.
6. Run the below command:
    ```sh
    terraform init
    ```
    This should successfully initialise the backend as you have set on your AWS account. If you find any errors, this will likely be linked to setting up your AWS credentials locally and/or AWS access permissions.

7. If you have made any amendments to the provided source code, it is recommended that you first run the below command as an initial check, troubleshooting any errors before deployment:
    ```sh
    terraform plan
    ```
8. Finally, run the below command:
    ```sh
    terraform apply -auto-approve
    ```
    This will then start the process of deploying the MWAA infrastructure and uploading the files necessary for running the DAG file "currency_exchange.py". Please note that this can take up to **60 minutes**.

Note that once deployed, MWAA is a live service that will continue to run indefinitely, and so costs can quickly acrue.

Decommissioning can be done by simply running the below command:
```sh
terraform destroy
```
This will destroy all created infrastructure, including generated S3 buckets and files, IAM roles and policies. Note that it will **not** destroy the Terraform backend file and associated S3 bucket. 

---

## Future developments
- Add ability to run Airflow locally (noting need to provide an S3 bucket name for outputting exchange rate data).