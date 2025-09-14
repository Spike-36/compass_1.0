import sqlite3
import json
from pathlib import Path

# Paths
DB_PATH = Path("/Users/petermilligan/Dev/Compass/Compass/compass.db")
NDJSON_PATH = Path("/Users/petermilligan/Dev/Compass/exports/testcompass3.capture.ndjson")


def main():
    if not NDJSON_PATH.exists():
        raise FileNotFoundError(f"NDJSON file not found: {NDJSON_PATH}")

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    inserted = 0
    skipped = 0

    with open(NDJSON_PATH, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            record = json.loads(line)

            doc_id = record.get("doc_id")
            block_type = record.get("block_type")
            block_number = record.get("block_number")
            sentence_index = record.get("sentence_index")
            text = record.get("text")

            # Skip if required fields missing
            if not (doc_id and text is not None):
                continue

            # Check for duplicates
            cur.execute("""
                SELECT 1 FROM sentences
                WHERE doc_id=? AND block_number=? AND sentence_index=?
            """, (doc_id, block_number, sentence_index))
            if cur.fetchone():
                skipped += 1
                continue

            cur.execute("""
                INSERT INTO sentences (doc_id, block_type, block_number, sentence_index, text)
                VALUES (?, ?, ?, ?, ?)
            """, (doc_id, block_type, block_number, sentence_index, text))
            inserted += 1

    conn.commit()
    conn.close()

    print(f"✅ Done. Inserted {inserted} rows, skipped {skipped} duplicates.")

if __name__ == "__main__":
    main()

