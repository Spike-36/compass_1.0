-- Sentences table
CREATE TABLE IF NOT EXISTS sentences (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    doc_id TEXT NOT NULL,
    block_type TEXT CHECK(block_type IN ('statement','answer')) NOT NULL,
    block_number INTEGER NOT NULL,
    sentence_index INTEGER NOT NULL,
    text TEXT NOT NULL
);

-- Helpful index for performance
CREATE INDEX IF NOT EXISTS idx_doc_block
  ON sentences (doc_id, block_type, block_number);

-- Links table (many-to-many connections between sentences)
CREATE TABLE IF NOT EXISTS links (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    statement_id INTEGER NOT NULL,
    response_id INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(statement_id, response_id),
    FOREIGN KEY(statement_id) REFERENCES sentences(id),
    FOREIGN KEY(response_id) REFERENCES sentences(id)
);
