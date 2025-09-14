
CREATE TABLE IF NOT EXISTS sentences (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    doc_id TEXT NOT NULL,
    block_type TEXT CHECK(block_type IN ('statement','answer')) NOT NULL,
    block_number INTEGER NOT NULL,
    sentence_index INTEGER NOT NULL,
    text TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_doc_block
  ON sentences (doc_id, block_type, block_number);
