#
# init_db.py
# Compass
#
# Created by Peter Milligan on 13/09/2025.

import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "compass.db"
SCHEMA_PATH = Path(__file__).with_name("schema.sql")

def main():
    conn = sqlite3.connect(DB_PATH)
    with open(SCHEMA_PATH, "r") as f:
        conn.executescript(f.read())
    conn.commit()
    conn.close()
    print(f"Database initialized at {DB_PATH}")

if __name__ == "__main__":
    main()
