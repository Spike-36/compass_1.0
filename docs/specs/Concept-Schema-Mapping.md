

# Concept → Schema Mapping (Compass MVP v1.4.2)

Plain-English MVP concepts on the left, exact schema/tables/fields on the right.
This version uses bullet points instead of tables for clean rendering in editors and GitHub.

---

## Document

* **Concept:** A pleading file (source text).
* **DB Table:** `documents`
* **Fields:** `id`, `title`, audit + soft-delete
* **Rules:** Hard-deleting cascades to everything under it (paragraphs → sentences → links/issue\_membership).

---

## Paragraph (aka Theme)

* **Concept:** Numbered pleading paragraph; can have a user label.
* **DB Table:** `paragraphs`
* **Fields:** `id`, `docId`, `paragraphNumber`, `name?`, `text`, audit + soft-delete
* **Rules:**

  * In MVP, Theme == Paragraph.
  * Live-only uniqueness on `(docId, paragraphNumber)` via partial index.
  * No cross-doc theming.

---

## Sentence (atomic unit)

* **Concept:** Single sentence row; status/labels/party; appears in virtualized list.
* **DB Table:** `sentences`
* **Fields:**

  * `id` = `${docId}-${para}-${sentIndex}`
  * `docId`, `paragraphId`, `paragraphNumber`, `sentenceIndex`
  * `text`, `systemLabel`, `status`, `partyId`, audit + soft-delete
* **Rules:** Status enum: `admitted` / `not_admitted` / `disputed` / `unknown` / `unset`.

---

## Sentence Labels

* **Concept:** Up to 10 user tags per sentence.
* **DB Table:** `sentence_labels`
* **Fields:** `sentenceId`, `pos (0..9)`, `label (ASCII ≤ 80)`
* **Rules:**

  * Max 10 enforced by trigger.
  * `(sentenceId, pos)` is PK.
  * Client repacks positions on delete.

---

## Party / Side

* **Concept:** Claimant / Defendant (displayed label).
* **DB Table:** `parties`
* **Fields:** `id`, `name`, `role` (`claimant` / `defendant`)

---

## Status

* **Concept:** Admitted / Not admitted / Disputed / Unknown / Unset.
* **DB:** `sentences.status` enum
* **UI Shortcut:** Keyboard A/N/D/U/Backspace.

---

## Link

* **Concept:** Connection between two sentences (e.g. claim ↔ response).
* **DB Table:** `links`
* **Fields:** `id`, `sourceSentenceId`, `targetSentenceId`, `type` (`claim_response`, `supports`)
* **Rules:**

  * No self-links.
  * Inverse trigger on `claim_response`.

---

## Issue

* **Concept:** Named topic that gathers sentences across paragraphs/docs.
* **DB Tables:** `issues`, `issue_sentences`
* **Fields:**

  * `issues`: `id`, `name`, `description?`
  * `issue_sentences`: `(issueId, position, sentenceId)`
* **Rules:**

  * Ordering explicit via `position`.
  * UNIQUE(issueId, sentenceId).
  * FK to sentences.

---

## Cross-doc Link UX

* **Concept:** Click badge opens target in secondary pane (not navigate away).
* **Rule:** Must keep context and maintain back stack.

---

## Undo / Redo

* **Concept:** In-memory only (20 steps).
* **Rules:**

  * Actions: `setStatus`, `create/deleteLink`, `add/removeFromIssue`, `renameParagraph`, `merge/splitSentence`.
  * Clears on refresh/import.

---

## Splitter Exceptions

* **Concept:** Config for sentence splitter.
* **Export Envelope:** `data.splitterExceptions[]`
* **Rules:** Versioned; included in export; treated as first-class test input.

---

## Import / Export Envelope

* **Concept:** Round-trippable JSON.
* **Fields:** `schemaVersion`, `exportedAt`, `data:{…}`
* **Rules:**

  * Must follow schema/v1.4.2.json.
  * Timestamps must be UTC Z.
  * Validate with JSON Schema on import and pre-save.

---

# Common Operations → Exact Writes/Reads

## Classify a sentence

* **UI:** Key press A/N/D/U/Backspace
* **DB:**

```sql
UPDATE sentences
SET status=?, updatedAt=?, updatedBy=?
WHERE id=? AND updatedAt=?;
```

* **Guard:** optimistic concurrency (409 on mismatch).

---

## Add / remove a label

* **Add:**

```sql
INSERT INTO sentence_labels(sentenceId,pos,label)
VALUES (?,?,?);
```

Client chooses next pos < 10.

* **Remove:**

```sql
DELETE FROM sentence_labels
WHERE sentenceId=? AND pos=?;
```

Client compacts remaining positions.

---

## Create a claim→response link

```sql
INSERT INTO links(id, sourceSentenceId, targetSentenceId, type, createdAt, updatedAt, createdBy, updatedBy)
VALUES (?,?,?,?,?,?,?,?);
```

* **Guards:** partial unique (live only), no self-links, inverse `claim_response` trigger.

---

## Add sentence to an issue (ordered)

```sql
INSERT INTO issue_sentences(issueId, position, sentenceId, addedAt, addedBy)
VALUES (?, ?, ?, ?, ?);
```

* **Rule:** client maintains dense positions 0..N (repack on delete).

---

## Merge / Split sentences (renumber)

* Build typed Old→New map.
* Run a single transaction:

  * Update affected `sentences.id` (and sentenceIndex, paragraphNumber if needed).
  * Rewrite `links.sourceSentenceId` / `links.targetSentenceId`.
  * Rewrite `issue_sentences.sentenceId`.
* Block reads or use snapshot isolation during transaction.

---

# Example Queries

## All disputed sentences in doc1, ordered

```sql
SELECT s.*
FROM sentences s
WHERE s.docId = 'doc1'
  AND s.status = 'disputed'
  AND s.deletedAt IS NULL
ORDER BY s.paragraphNumber, s.sentenceIndex;
```

## Linked pairs (claim\_response) with texts

```sql
SELECT a.id AS sourceId, a.text AS sourceText,
       b.id AS targetId, b.text AS targetText
FROM links l
JOIN sentences a ON a.id = l.sourceSentenceId AND a.deletedAt IS NULL
JOIN sentences b ON b.id = l.targetSentenceId AND b.deletedAt IS NULL
WHERE l.type = 'claim_response'
  AND l.deletedAt IS NULL;
```

## Issue view (ordered sentences with paragraph labels)

```sql
SELECT isen.position, s.id, s.text, p.paragraphNumber, p.name
FROM issue_sentences isen
JOIN sentences s ON s.id = isen.sentenceId AND s.deletedAt IS NULL
JOIN paragraphs p ON p.id = s.paragraphId AND p.deletedAt IS NULL
WHERE isen.issueId = 'iss-1'
ORDER BY isen.position ASC;
```

---

# UI Mapping Cheatsheet

* **Paragraph view:** query paragraphs + join sentences by (docId, paragraphId); show `paragraphNumber`, `name`, and each sentence’s status + labels.
* **Theme view:** identical to paragraph view; treat `name` as the theme label.
* **Issue map:** drive list from `issue_sentences ORDER BY position`; render sentence rows with inline paragraph badge (`paragraphNumber` / `name`).
* **Linking mode:** show link badges/indents by joining links where `sourceSentenceId = current` or `targetSentenceId = current`.
* **Cross-doc link click:** open target in secondary pane; show doc title badge near the inline preview.

---

# Guardrails

* UTC timestamps only (must end in `Z`) at all layers.
* JSON Schema v1.4.2 on import and pre-save.
* Optimistic concurrency on every write (`updatedAt` check → 409).
* Virtualized list for any sentence mass rendering (target: 10k, <50ms/frame).
* Undo/redo never persisted.
* ASCII labels only; DB enforces cap and uniqueness by `(sentenceId, pos)`.

---

# Optional Deliverables

* One-page PDF “MVP Concept ↔ Schema” handout for stakeholders.
* Swift repository helpers (e.g., `SentenceRepository.setStatus(...)`, `LinkRepository.create(...)`) so UI code never touches raw SQL.

---
