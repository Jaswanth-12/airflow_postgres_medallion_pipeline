import os
from datetime import datetime
import pandas as pd
from sqlalchemy import create_engine
from airflow.sdk import dag, task
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator

# --- INJECT CONNECTION DIRECTLY INTO AIRFLOW ENVIRONMENT ---
os.environ["AIRFLOW_CONN_POSTGRES_DEFAULT"] = (
    "postgres://postgres:postgres@localhost:5432/postgres"
)

DB_CONN = "postgresql+psycopg2://postgres:postgres@localhost:5432/postgres"

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

@dag(
    dag_id="medallion_postgres_pipeline",
    start_date=datetime(2026, 1, 1),
    schedule="@daily",
    catchup=False,
    template_searchpath=[BASE_DIR],
    tags=["medallion", "postgresql", "data_warehouse"],
)
def medallion_pipeline():

    # 1. CREATE BRONZE TABLES
    create_bronze_tables = SQLExecuteQueryOperator(
        task_id="01_create_bronze_tables",
        conn_id="postgres_default",
        sql="sql/01_bronze_layer.sql",
    )

    # 2. AUTOMATIC CSV INGESTION TO BRONZE SCHEMA
    @task(task_id="02_load_csvs_to_bronze")
    def load_csv_to_bronze():
        engine = create_engine(DB_CONN)
        
        csv_mappings = {
            "crm_cust_info": os.path.join(BASE_DIR, "datasets", "crm", "cust_info.csv"),
            "crm_prd_info": os.path.join(BASE_DIR, "datasets", "crm", "prd_info.csv"),
            "crm_sales_details": os.path.join(BASE_DIR, "datasets", "crm", "sales_details.csv"),
            "erp_cust_az12": os.path.join(BASE_DIR, "datasets", "erp", "CUST_AZ12.csv"),
            "erp_loc_a101": os.path.join(BASE_DIR, "datasets", "erp", "LOC_A101.csv"),
            "erp_px_cat_g1v2": os.path.join(BASE_DIR, "datasets", "erp", "PX_CAT_G1V2.csv"),
        }
        
        for table_name, csv_path in csv_mappings.items():
            if os.path.exists(csv_path):
                df = pd.read_csv(csv_path)
                # Normalise column names to lowercase
                df.columns = [c.strip().lower() for c in df.columns]
                df.to_sql(
                    name=table_name, 
                    schema="bronze", 
                    con=engine, 
                    if_exists="replace", 
                    index=False
                )
                print(f"[Bronze] Successfully loaded {len(df)} rows into bronze.{table_name}")
            else:
                print(f"[ERROR] File not found at: {csv_path}")

    # 3. RUN SILVER LAYER
    run_silver = SQLExecuteQueryOperator(
        task_id="03_run_silver_layer",
        conn_id="postgres_default",
        sql="sql/02_silver_layer.sql",
    )

    # 4. RUN GOLD LAYER
    run_gold = SQLExecuteQueryOperator(
        task_id="04_run_gold_layer",
        conn_id="postgres_default",
        sql="sql/03_gold_layer.sql",
    )

    create_bronze_tables >> load_csv_to_bronze() >> run_silver >> run_gold

medallion_pipeline()