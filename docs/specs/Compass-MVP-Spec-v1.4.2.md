Here’s your revised **Spec v1.4.2**, updated to (1) clarify it’s a **Swift macOS app** (not iOS), and (2) capture that lawyers work from pleadings of numbered paragraphs, but the real analytical unit is the **sentence**, which can be linked (claim ↔ response) into issues. I’ve slotted the changes where they fit the existing structure without breaking the locked versioning style:

---

# Compass MVP — Spec v1.4.2 (Locked, macOS)

## Scope

**Platform:**
Swift macOS desktop application (AppKit/SwiftUI).
Lawyers primarily work from pleadings containing **numbered paragraphs**.
The core analysis happens at the **sentence level** (admitted / denied / disputed), with claims ↔ responses linked into issues for the court to decide.
Traditional Word/PDF workflows are fragile when pleadings are amended (new words, sentences, or paragraphs inserted/deleted). Compass is designed to handle these changes safely.

**MVP flow:**
import → split → classify → link → group into issues → export JSON

**Classify:**
admitted | not\_admitted | disputed | unknown | unset

**Link types:**
claim\_response | supports | contradicts | cites

**Out of scope:**
per-party matrices, sub-themes, analytics, fancy viz

---

## Core Entities

**Document**

**Party**

* role = claimant | defendant | other

**Paragraph (= Theme)**

* Numbered units as in pleadings
* Each groups one or more sentences

**Sentence**

* atomic unit of analysis
* partyId
* systemLabel
* labels\[≤10, ASCII ≤80]

**Link**

* directional
* no self
* no inverse claim\_response

**Issue**

**IssueMembership**

* ordered

*All soft-delete, UTC timestamps, cross-doc links allowed*

---

## Deterministic IDs & Renumbering

**Sentence IDs:**
`${docId}-${para}-${sentIndex}`

**Renumbering (for amended pleadings):**

* Old→New ID map
* Atomic rewrite of links & issue memberships
* Supports insertions/deletions of words, sentences, or paragraphs without corrupting references

---

## Undo / Redo

* In-memory only
* Cleared on refresh/import
* Buffer = 20 actions

---

## Validation & Import/Export

* JSON Schema enforced on import and pre-save
* Splitter config versioned (`splitterExceptions.json`)
* Same-doc constraint: `sentence.paragraphId` must match doc

---

## Concurrency & Transactions

* Optimistic concurrency via `updatedAt`; mismatch = **409**
* Renumber runs transactionally with snapshot isolation
* Undo buffer resets on reload/import

---

## Performance Guardrails

* Virtualized lists, batched updates, no per-keystroke full reflows
* Target: **10k sentences**, <50ms/frame on mid-tier Mac hardware
* Repo ships with fixtures: `mini.json`, `stress-10k.json`

---

## API / UX Clarifications

* Cross-doc link opens secondary pane (not full nav)
* Keyboard map (macOS):

  * `A / N / D / U / Backspace`
  * `L + ↑ ↓ / Enter / Esc`
  * `Undo / Redo`
* Keys disabled in modal to avoid collisions
* macOS conventions: menu bar commands, resizable windows, drag-and-drop import/export

---

## Error Codes

* **400** validation\_failed
* **409** edit\_conflict
* **422** inverse\_claim\_response\_forbidden
* **429** label\_cap\_exceeded
* **500** transaction\_failed

---

## “Ship” Checklist

* `PRAGMA foreign_keys=ON`
* CI: import `stress-10k.json` → run validators → renumber → assert integrity
* Golden round-trip: import → edits → export → re-import → byte-compare
* Seed parties: `p1 = Claimant`, `p2 = Defendant`
* Document rollback on failed renumber

---

This version keeps all your locked technical detail, but:

* **Up front**: nails platform = macOS.
* **Paragraph/Sentence relationship**: explicitly tied to pleadings.
* **Renumbering**: expanded to handle insertions/deletions at any level.
* **Performance/UI**: benchmarked on Mac hardware, with desktop UX conventions.

Do you want me to also **revise the error codes** section to cover failure modes specific to amended pleadings (e.g. “404 old\_sentence\_id\_missing\_after\_renumber”), or keep them lean for now?
