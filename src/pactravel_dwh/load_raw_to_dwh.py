from __future__ import annotations

import argparse
import json
import logging
import os
from pathlib import Path
from typing import Iterable

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import Engine, URL

load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)
logger = logging.getLogger("pactravel_raw_loader")

SRC_SCHEMA = os.getenv("SRC_SCHEMA", "public")
RAW_SCHEMA = os.getenv("RAW_SCHEMA", "pactravel")
STATE_DIR = Path(os.getenv("STATE_DIR", ".state/raw"))

MASTER_TABLES: list[str] = [
    "customers",
    "airlines",
    "aircrafts",
    "airports",
    "hotel",
]

TRANSACTION_TABLES: list[str] = [
    "flight_bookings",
    "hotel_bookings",
]

ALL_TABLES: list[str] = MASTER_TABLES + TRANSACTION_TABLES

TRUNCATE_ORDER: list[str] = [
    "hotel_bookings",
    "flight_bookings",
    "hotel",
    "airports",
    "aircrafts",
    "airlines",
    "customers",
]


def get_env(name: str, default: str | None = None) -> str:
    value = os.getenv(name, default)
    if value is None or value == "":
        raise ValueError(f"Missing required environment variable: {name}")
    return value


def build_engine(
    host: str,
    port: int,
    dbname: str,
    user: str,
    password: str,
) -> Engine:
    url = URL.create(
        drivername="postgresql+psycopg2",
        username=user,
        password=password,
        host=host,
        port=port,
        database=dbname,
    )
    return create_engine(url, future=True)


def get_source_engine() -> Engine:
    return build_engine(
        host=get_env("SRC_POSTGRES_HOST", "localhost"),
        port=int(get_env("SRC_POSTGRES_PORT", "5433")),
        dbname=get_env("SRC_POSTGRES_DB"),
        user=get_env("SRC_POSTGRES_USER"),
        password=get_env("SRC_POSTGRES_PASSWORD"),
    )


def get_dwh_engine() -> Engine:
    return build_engine(
        host=get_env("DWH_POSTGRES_HOST", "localhost"),
        port=int(get_env("DWH_POSTGRES_PORT", "5434")),
        dbname=get_env("DWH_POSTGRES_DB"),
        user=get_env("DWH_POSTGRES_USER"),
        password=get_env("DWH_POSTGRES_PASSWORD"),
    )


def ensure_schema_exists(dwh_engine: Engine, schema_name: str) -> None:
    logger.info("Ensuring schema exists: %s", schema_name)
    with dwh_engine.begin() as conn:
        conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {schema_name}"))


def assert_tables_exist(
    engine: Engine,
    schema_name: str,
    tables: Iterable[str],
    label: str,
) -> None:
    inspector = inspect(engine)
    missing = [
        table_name
        for table_name in tables
        if not inspector.has_table(table_name, schema=schema_name)
    ]
    if missing:
        raise RuntimeError(
            f"{label} tables not found in schema '{schema_name}': {missing}"
        )


def truncate_tables(dwh_engine: Engine, schema_name: str, table_names: list[str]) -> None:
    fq_tables = ", ".join(f"{schema_name}.{table_name}" for table_name in table_names)
    logger.info("Truncating target tables: %s", fq_tables)

    with dwh_engine.begin() as conn:
        conn.execute(text(f"TRUNCATE TABLE {fq_tables};"))


def extract_table(source_engine: Engine, schema_name: str, table_name: str) -> pd.DataFrame:
    logger.info("Extracting source table: %s.%s", schema_name, table_name)
    query = text(f"SELECT * FROM {schema_name}.{table_name}")
    return pd.read_sql_query(query, source_engine)


def load_table(
    dwh_engine: Engine,
    schema_name: str,
    table_name: str,
    df: pd.DataFrame,
) -> int:
    logger.info(
        "Loading %s rows into target table: %s.%s",
        len(df),
        schema_name,
        table_name,
    )

    with dwh_engine.begin() as conn:
        df.to_sql(
            name=table_name,
            con=conn,
            schema=schema_name,
            if_exists="append",
            index=False,
            method="multi",
            chunksize=1000,
        )

    return len(df)


def save_run_summary(summary: dict) -> Path:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    output_path = STATE_DIR / "load_raw_summary.json"
    output_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    return output_path


def run_full_refresh() -> dict:
    source_engine = get_source_engine()
    dwh_engine = get_dwh_engine()

    ensure_schema_exists(dwh_engine, RAW_SCHEMA)

    assert_tables_exist(source_engine, SRC_SCHEMA, ALL_TABLES, "Source")
    assert_tables_exist(dwh_engine, RAW_SCHEMA, ALL_TABLES, "Target")

    truncate_tables(dwh_engine, RAW_SCHEMA, TRUNCATE_ORDER)

    results: list[dict] = []

    for table_name in ALL_TABLES:
        df = extract_table(source_engine, SRC_SCHEMA, table_name)
        row_count = load_table(dwh_engine, RAW_SCHEMA, table_name, df)

        results.append(
            {
                "table_name": table_name,
                "row_count": row_count,
                "status": "SUCCESS",
            }
        )

    summary = {
        "status": "SUCCESS",
        "source_schema": SRC_SCHEMA,
        "target_schema": RAW_SCHEMA,
        "tables_loaded": len(results),
        "results": results,
    }

    output_path = save_run_summary(summary)
    logger.info("Full refresh completed successfully")
    logger.info("Summary written to: %s", output_path)
    return summary


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Load raw PacTravel tables from source DB to DWH raw schema"
    )
    args = parser.parse_args()
    run_full_refresh()


if __name__ == "__main__":
    main()