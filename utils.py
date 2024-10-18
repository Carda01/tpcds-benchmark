import psycopg2
import os
from psycopg2 import Error
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from dotenv import load_dotenv

def connect_postgres(db_name):
    load_dotenv()
    try:
        # Connect to an existing database
        connection = psycopg2.connect(database = db_name)
        # Set auto-commit
        connection.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT);
        # Create a cursor to perform database operations
        cur = connection.cursor()
        # Print PostgreSQL details
        print("PostgreSQL server information")
        print(connection.get_dsn_parameters(), "\n")
        # Executing a SQL query
        cur.execute("SELECT version();")
        # Fetch result
        record = cur.fetchone()
        print("You are connected to - ", record, "\n")

    except (Exception, Error) as error:
        print("Error while connecting to PostgreSQL", error)
    else:
        return cur


def get_all_files_in_directory(d):
    return [os.path.join(d, f) for f in os.listdir(d)]


def get_files_absolute_path_from_dir(path):
    files_abs_path = [p.replace('\\', '/') for p in get_all_files_in_directory(path)]
    print("Total files:", len(files_abs_path))
    print("First few files...")
    print(files_abs_path[:5])
    return files_abs_path


def exclude_non_csv_files(file_list):
    return list(filter(lambda x: x.endswith('.csv'), file_list))


def execute_sql(connection, relative_path):
    connection.execute(open(relative_path, "r").read())
    print("SQL Status Output:\n", connection.statusmessage)

