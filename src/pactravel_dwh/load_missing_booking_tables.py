from sqlalchemy import create_engine, text
import pandas as pd

SRC_URL = "postgresql+psycopg2://postgres:mypassword@localhost:5433/pactravel"
DWH_URL = "postgresql+psycopg2://postgres:mypassword@localhost:5434/pactravel-dwh"

src_engine = create_engine(SRC_URL)
dwh_engine = create_engine(DWH_URL)

TABLES = ["flight_bookings", "hotel_bookings"]


def main() -> None:
    with dwh_engine.begin() as conn:
        conn.execute(text("create schema if not exists pactravel"))

    for table in TABLES:
        print(f"Reading source.public.{table} ...")
        df = pd.read_sql(f"select * from public.{table}", src_engine)
        print(f"Rows read: {len(df)}")

        df.to_sql(
            name=table,
            con=dwh_engine,
            schema="pactravel",
            if_exists="replace",
            index=False,
            method="multi",
            chunksize=1000,
        )

        print(f"Loaded into pactravel.{table}")


if __name__ == "__main__":
    main()