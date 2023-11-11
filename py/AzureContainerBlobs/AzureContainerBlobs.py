import logging
import asyncio
from typing import List, Optional
from pathlib import Path
from csv import DictWriter

import typer
from azure.storage.blob.aio import BlobServiceClient

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
                    'name',
                    'container',
                    'size',
                    'tags',
                    'lae',
                    'log source',
                    'log year',
                    'log month',
                    'log day'
                ],
            )
            writer.writeheader()
            for entry in repdata:
                writer.writerow(entry)
    else:
        logger.critical ("CHECK-FAIL: Missing report path and/or report data")


async def requester(account_url: str, container: str, credential) -> List[dict]:
    if account_url and container and credential:
        blob_service_client = BlobServiceClient(account_url, credential=credential)
        container_client = blob_service_client.get_container_client(container=container)

        reqlog = []
        async for blob in container_client.list_blobs():
            name_split = blob.name.split("/")
            file_name = name_split[-1].split("-")
            if file_name[0] == 'test.txt':
                pass
            else:
                log_ts_ext = file_name[-1].split(".")
                log_ts = log_ts_ext[0]
                if int(log_ts[0:4]) in range(1, 9):
                    log_ts = file_name[-2]
                reqdata = {
                    'name': blob.name,
                    'container': blob.container,
                    'size': blob.size,
                    'tags': blob.tags,
                    'lae': name_split[0],
                    'log source': file_name[0],
                    'log year': log_ts[0:4],
                    'log month': log_ts[4:6],
                    'log day': log_ts[6:8]
                }
                reqlog.append(reqdata)
        print(len(reqlog))
        return reqlog
    else:
        logger.critical("CHECK-FAIL: Missing account and/or container")


@app.command()
def bloblist(
    account: str = typer.Option(help="Azure storage account"),
    container: str = typer.Option(help="The name of the container for the blob"),
    credential: str = typer.Option(help="SAS token"),
    report: Path = typer.Option(help="Filepath for report output"),
    verbose: Optional[int] = typer.Option(0, "--verbose", "-v", count=True, max=4, help="Log verbosity level"
    ),
):
    if account and report and container and credential:
        logging.basicConfig(level=(((verbose + 5) * 10) - (verbose * 20)))
        account_url = f'https://{account}.blob.core.windows.net'
        reporter(
            reppath=report,
            repdata=(
                asyncio.run(
                    requester(
                        account_url=account_url,
                        container=container,
                        credential=credential
                    )
                )
            )
        )
    else:
        logger.critical("CHECK-FAIL: Missing account, container, and/or report path")


if __name__ == "__main__":
    app()