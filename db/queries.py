#
//  queries.py
//  Compass
//
//  Created by Peter Milligan on 13/09/2025.
//

import sqlite3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "compass.db"

def list_by_doc(doc_id: str):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    for row in cur.execute("""
        SELECT block_type, block_number, sentence_index, text
        FROM sentences
        WHERE doc_id = ?
        ORDER BY block_number, sentence_index
    """, (doc_id,)):
        print(row)
    conn.close()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python db/queries.py <doc_id>")
        sys.exit(1)
    list_by_doc(sys.argv[1])
