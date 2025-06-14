import sqlite3
import logging
import typer

app = typer.Typer()


def backup_database(source_db_path: str, backup_db_path: str):
    """
    Backs up an SQLite database from the source path to the backup path.

    Args:
        source_db_path (str): Path to the source SQLite database.
        backup_db_path (str): Path to the backup SQLite database.

    Raises:
        sqlite3.Error: If there's an issue during backup.
    """
    try:
        # Connect to the source and backup databases
        source_conn = sqlite3.connect(source_db_path)
        backup_conn = sqlite3.connect(backup_db_path)

        with backup_conn:
            source_conn.backup(backup_conn)
        logging.info(
            f"Backup completed successfully from {source_db_path} to {backup_db_path}"
        )

    except sqlite3.Error as e:
        logging.error(f"Error occurred during backup: {e}")
        raise
    finally:
        # Ensure both connections are closed
        source_conn.close()
        backup_conn.close()


def progress_report(status: int, remaining: int, total: int):
    """
    Reports the progress of the backup operation.

    Args:
        status (int): The status of the backup.
        remaining (int): Pages remaining to be backed up.
        total (int): Total number of pages to be backed up.
    """
    logging.info(
        f"Backup progress: {total - remaining} pages out of {total} backed up."
    )


@app.command()
def backup(
    source: str = typer.Option(help="Source DB"),
    destination: str = typer.Option(help="Backup DB destination"),
):
    """
    Command-line interface to run the backup operation.

    Args:
        source_db (str): Path to the source SQLite database.
        backup_db (str): Path to the backup SQLite database.
    """
    if source and destination:
        backup_database(source, destination)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    app()
