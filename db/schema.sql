-- =========================
-- Compass Database Schema
-- =========================

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

-- =========================
-- Issues support
-- =========================

-- Issues table (flat list now, parent_id supports nesting later if needed)
CREATE TABLE IF NOT EXISTS issues (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    parent_id INTEGER,              -- NULL = top-level issue
    sort_order INTEGER DEFAULT 0,   -- for drag/drop ordering
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(parent_id) REFERENCES issues(id)
);

-- Mapping table between issues and sentences
CREATE TABLE IF NOT EXISTS issue_sentences (
    issue_id INTEGER NOT NULL,
    sentence_id INTEGER NOT NULL,
    PRIMARY KEY (issue_id, sentence_id),
    FOREIGN KEY(issue_id) REFERENCES issues(id),
    FOREIGN KEY(sentence_id) REFERENCES sentences(id)
);

-- Index to make reordering faster
CREATE INDEX IF NOT EXISTS idx_issue_sort
  ON issues (parent_id, sort_order);

-- =========================
-- Seed data
-- =========================

INSERT INTO issues (title, sort_order)
SELECT 'General Issue 1', 0
WHERE NOT EXISTS (SELECT 1 FROM issues);

