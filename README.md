# Currency Exchange (MWAA)

## Overview
This project automates the collection of daily exchange rate data for GBP against selected currencies (default of USD and EUR). It includes:
- **Python code** to fetch and process currency data.
- **Terraform scripts** to deploy the workflow to **AWS Managed Workflows for Apache Airflow (MWAA)**.
- **Makefile** and **python tests** for automation and validation.

The purpose of this repository is to demonstrate how to orchestrate data workflows using Apache Airflow both locally and in the cloud (AWS MWAA).

Pair programmed project developed using Agile methodologies by [Aran Parrish](https://github.com/AranParrish) and [Michael Lee](https://github.com/15ML).

---

## Prerequisites
Before you begin, ensure you have the following installed and configured:

- **Make** (search online for installation instructions relevant to your operating system)
- **Python 3.12**

You should also have a basic understanding of orchestration with Apache Airflow.

---

## Getting Started
Clone the repository to your local directory and cd into the root directory:

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
└── Dockerfile      # Dockerfile for setting up local developer environment
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
- **AWS CLI** (configured with sufficient permissions to create MWAA, S3, and IAM resources)
- **AWS Account**
- **Terraform**

Need to add instructions for setting the Terraform statefile.

---

## Future developments
- Amend Makefile to use Docker instead of venv for local dev setup.
- Add ability to run Airflow locally (noting need to provide an S3 bucket name for outputting exchange rate data).