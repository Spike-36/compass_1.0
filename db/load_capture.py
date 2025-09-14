# load_capture.py
# Compass
#
# Created by Peter Milligan on 13/09/2025.

import sqlite3, json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "compass.db"
EXPORTS = ROOT / "exports"

def ensure_schema(conn):
    """Create tables if they don't exist yet."""
    conn.execute("""
        CREATE TABLE IF NOT EXISTS sentences (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            doc_id TEXT NOT NULL,
            block_type TEXT NOT NULL,
            block_number INTEGER NOT NULL,
            sentence_index INTEGER NOT NULL,
            text TEXT NOT NULL
        )
    """)

def load_file(ndjson_path: Path):
    with sqlite3.connect(DB_PATH) as conn:
        ensure_schema(conn)
        cur = conn.cursor()
        count = 0
        with ndjson_path.open("r", encoding="utf-8") as f:
            for line in f:
                if not line.strip():
                    continue
                row = json.loads(line)
                cur.execute("""
                    INSERT INTO sentences (doc_id, block_type, block_number, sentence_index, text)
                    VALUES (?, ?, ?, ?, ?)
                """, (
                    row["doc_id"],
                    row["block_type"],
                    int(row["block_number"]),
                    int(row["sentence_index"]),
                    row["text"]
                ))
                count += 1
        conn.commit()
    print(f"Loaded {count} rows from {ndjson_path} into {DB_PATH}")

def main():
    # usage: python db/load_capture.py testcompass2.capture.ndjson
    if len(sys.argv) != 2:
        print("Usage: python db/load_capture.py <capture_file.ndjson>")
        sys.exit(1)
    nd = Path(sys.argv[1])
    if not nd.is_absolute():
        nd = EXPORTS / nd
    if not nd.exists():
        print(f"Not found: {nd}")
        sys.exit(1)
    load_file(nd)

if __name__ == "__main__":
    main()

