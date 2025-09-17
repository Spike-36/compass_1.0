# queries.py
# Compass
#
# Created by Peter Milligan on 13/09/2025.

import sqlite3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "compass.db"

def list_by_doc(doc_id: str):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    for row in cur.execute("""
        SELECT id, block_type, block_number, sentence_index, text
        FROM sentences
        WHERE doc_id = ?
        ORDER BY block_number, sentence_index
    """, (doc_id,)):
        print(row)
    conn.close()

# === NEW HELPERS FOR LINKS ===

def insert_link(statement_id: int, response_id: int):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    # Fetch metadata for both sentences
    cur.execute("SELECT doc_id, block_number, block_type FROM sentences WHERE id = ?", (statement_id,))
    stmt_row = cur.fetchone()
    cur.execute("SELECT doc_id, block_number, block_type FROM sentences WHERE id = ?", (response_id,))
    resp_row = cur.fetchone()

    if not stmt_row or not resp_row:
        conn.close()
        raise ValueError("❌ One of the sentence IDs does not exist.")

    stmt_doc, stmt_block, stmt_type = stmt_row
    resp_doc, resp_block, resp_type = resp_row

    # Enforce linking rules
    if stmt_doc != resp_doc:
        conn.close()
        raise ValueError("❌ Sentences are from different documents.")
    if stmt_block != resp_block:
        conn.close()
        raise ValueError("❌ Sentences are from different blocks.")
    if stmt_type != "statement":
        conn.close()
        raise ValueError("❌ First ID must be a statement.")
    if resp_type != "answer":
        conn.close()
        raise ValueError("❌ Second ID must be an answer.")

    # Passed all checks → insert
    cur.execute("""
        INSERT OR IGNORE INTO links (statement_id, response_id)
        VALUES (?, ?)
    """, (statement_id, response_id))
    conn.commit()
    conn.close()

def delete_link(link_id: int):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    cur.execute("DELETE FROM links WHERE id = ?", (link_id,))
    conn.commit()
    conn.close()

def fetch_links(doc_id: str, block_number: int):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    cur.execute("""
        SELECT l.id, s.text, r.text
        FROM links l
        JOIN sentences s ON l.statement_id = s.id
        JOIN sentences r ON l.response_id = r.id
        WHERE s.doc_id = ? AND r.doc_id = ?
          AND s.block_number = ? AND r.block_number = ?
        ORDER BY l.created_at
    """, (doc_id, doc_id, block_number, block_number))
    rows = cur.fetchall()
    conn.close()
    return rows

# === COMMAND-LINE ENTRY POINT ===

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python db/queries.py list <doc_id>")
        print("  python db/queries.py links <doc_id> <block_number>")
        print("  python db/queries.py testlink <doc_id> <block_number> <stmt_id> <resp_id>")
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "list" and len(sys.argv) == 3:
        list_by_doc(sys.argv[2])

    elif cmd == "links" and len(sys.argv) == 4:
        doc_id = sys.argv[2]
        block_number = int(sys.argv[3])
        rows = fetch_links(doc_id, block_number)
        if not rows:
            print("(no links found)")
        else:
            for lid, stmt, resp in rows:
                print(f"[{lid}] {stmt} -> {resp}")

    elif cmd == "testlink" and len(sys.argv) == 6:
        doc_id = sys.argv[2]
        block_number = int(sys.argv[3])
        stmt_id = int(sys.argv[4])
        resp_id = int(sys.argv[5])

        try:
            insert_link(stmt_id, resp_id)
            print(f"✅ Inserted link {stmt_id} → {resp_id}")
        except ValueError as e:
            print(e)
            sys.exit(1)

        rows = fetch_links(doc_id, block_number)
        if not rows:
            print("(no links found)")
        else:
            print("Current links in block", block_number)
            for lid, stmt, resp in rows:
                print(f"[{lid}] {stmt} -> {resp}")

    else:
        print("Invalid usage.")
        print("  python db/queries.py list <doc_id>")
        print("  python db/queries.py links <doc_id> <block_number>")
        print("  python db/queries.py testlink <doc_id> <block_number> <stmt_id> <resp_id>")
        sys.exit(1)
