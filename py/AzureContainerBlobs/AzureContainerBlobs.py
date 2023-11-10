import logging
from typing import List
from pathlib import Path
from csv import DictWriter

import typer
from rich.progress import track
from azure.identity import DefaultAzureCredential
from azure.storage.blob import ContainerClient

__author__ = "Lickitysplitted"
__version__ = "0.0.1"

app = typer.Typer()
logger = logging.getLogger(__name__)


def reporter(reppath: Path, repdata: List[dict]) -> None:
    if reppath and repdata:
        with open(reppath.resolve(), "a", encoding="utf-8") as repobj:
            writer = DictWriter(
                repobj,
                [
                    "account",
                    "container",
                    "blob"
                ],
            )
            writer.writeheader()
            for entry in repdata:
                writer.writerow(
                    {
                        "account": entry.get("account"),
                        "container": entry.get("container"),
                        "blob": entry.get("blob")
                    }
                )
    else:
        logger.warn("CHECK-FAIL: Missing report path and/or report data")


async def request(account_url: str, container: str, credential) -> List[dict]:
    if account_url and container:
        container_client = ContainerClient(account_url=account_url, container_name=container, credential=credential)
        blobs = container_client.list_blob_names()
        reqlog = []
        for blob in track(blobs):
            reqdata = {
                "account",
                "container",
                blob
            }
            reqlog.append(reqdata)
        return reqlog
    else:
        logger.warn("CHECK-FAIL: Missing account and/or container")


@app.command()
def bloblist(
    account: str = typer.Option(help="Azure storage account"),
    container: str = typer.Option(help="The name of the container for the blob."),
    report: Path = typer.Option(help="Filepath for report output"),
    verbose: int = typer.Option(0, "--verbose", "-v", count=True, max=4, help="Log verbosity level"
    ),
):
    if account and report and container:
        logging.basicConfig(level=(verbose * 10) - 40)
        account_url = "https://{account}.blob.core.windows.net"
        report = Path(report)
        default_credential = DefaultAzureCredential()
        reporter(
            reppath=report,
            repdata=(
                request(
                    account_url=account_url,
                    container=container,
                    credential=default_credential
                    )
            )
        )
    else:
        logger.warn("CHECK-FAIL: Missing account, container, and/or report path")


if __name__ == "__main__":
    app()