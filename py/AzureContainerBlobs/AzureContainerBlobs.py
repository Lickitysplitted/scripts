import logging
from pathlib import Path

import typer
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient, BlobClient, ContainerClient

__author__ = "Lickitysplitted"
__version__ = "0.0.1"

app = typer.Typer()
logger = logging.getLogger(__name__)


@app.command()
def bloblist(
    account: str = typer.Option(help="Azure storage account"),
    report: Path = typer.Option(help="Filepath for report output"),
    container: str = typer.Option(help="The name of the container for the blob."),
    verbose: int = typer.Option(0, "--verbose", "-v", count=True, max=4, help="Log verbosity level"
    ),
):
    if account and report and container:
        logging.basicConfig(level=(verbose * 10) - 40)
        account_url = 'https://{account}.blob.core.windows.net'
        report = Path(report)
        default_credential = DefaultAzureCredential()
        container_client = ContainerClient(account_url=account_url, container_name=container, credential=default_credential)


        # List the blobs in the container
        blobs = container_client.list_blob_names()
        for blob in blobs:
            print("\t" + blob)


if __name__ == "__main__":
    app()