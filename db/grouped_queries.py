# grouped_queries.py
# Compass
#
# Created by Peter Milligan on 13/09/2025.

import sqlite3
from pathlib import Path
import sys
from collections import defaultdict

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "compass.db"

def list_grouped_by_block(doc_id: str):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    cur.execute("""
        SELECT block_type, block_number, sentence_index, text
        FROM sentences
        WHERE doc_id = ?
        ORDER BY block_number, block_type, sentence_index
    """, (doc_id,))
    rows = cur.fetchall()
    conn.close()

    # group by block_number
    grouped = defaultdict(lambda: {"statement": [], "answer": []})
    for bt, bn, si, text in rows:
        grouped[bn][bt].append((si, text))

    # pretty print
    for block_num in sorted(grouped.keys()):
        print(f"\n=== Block {block_num} ===")
        for si, text in grouped[block_num]["statement"]:
            print(f"  [S{block_num}.{si}] {text}")
        for si, text in grouped[block_num]["answer"]:
            print(f"  [A{block_num}.{si}] {text}")

def main():
    if len(sys.argv) != 2:
        print("Usage: python db/grouped_queries.py <doc_id>")
        sys.exit(1)
    list_grouped_by_block(sys.argv[1])

if __name__ == "__main__":
    main()
