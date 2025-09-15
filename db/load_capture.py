# load_capture.py
# Compass
#
# Load .capture.ndjson into the sentences table, replacing any prior rows for that doc_id.

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
            # read first line
            first_line = json.loads(next(f))
            doc_id = first_line["doc_id"]
            # clear any previous entries for this document
            cur.execute("DELETE FROM sentences WHERE doc_id = ?", (doc_id,))
            # insert first line
            cur.execute("""
                INSERT INTO sentences (doc_id, block_type, block_number, sentence_index, text)
                VALUES (?, ?, ?, ?, ?)
            """, (
                first_line["doc_id"],
                first_line["block_type"],
                int(first_line["block_number"]),
                int(first_line["sentence_index"]),
                first_line["text"]
            ))
            count = 1
            # process the rest
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
    print(f"Loaded {count} fresh rows for {doc_id} from {ndjson_path}")

def main():
    # usage: python3 load_capture.py <capture_file.ndjson>
    if len(sys.argv) != 2:
        print("Usage: python3 load_capture.py <capture_file.ndjson>")
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

