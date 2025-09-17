# ✅ Compass Test Checklist

## 1. Schema & Fixtures
- [ ] Validate `fixtures/mini.json` against `schema/v1.4.2.json`.
- [ ] Validate `fixtures/stress-10k.json` against `schema/v1.4.2.json`.
- [ ] Round-trip test: import → export → byte-compare (ignoring `updatedAt`).

## 2. Database
- [ ] Apply latest migration to `compass.db` cleanly.
- [ ] Verify partial unique index on `paragraph` (live rows only).
- [ ] Confirm link constraint (forbid inverse `claim_response`).

## 3. Swift Guards
- [ ] `IDSpec.swift` enforces regex `doc-para-sent`.
- [ ] `DocumentIdentity.swift` validates timestamps end with `Z`.
- [ ] Edits rejected with HTTP 409 if `updatedAt` mismatch.

## 4. Error Handling Guardrails
- [ ] **409 Conflict (stale update)**
  - `ServiceError.conflict409` returned from Swift layer.
  - UI shows non-blocking banner: “This text was updated elsewhere. Please reload.”
  - User can **Reload** to refresh data, or **Dismiss**. Further edits blocked until reload.

- [ ] **Offline**
  - Loss of network → show “You appear to be offline.”
  - Editing disabled until reconnected.

- [ ] **500+ Server Errors**
  - Generic message: “Something went wrong, please try again.”
  - Retry option visible.

- [ ] **Validation Errors (400)**
  - Inline highlight at field/row.
  - Error message shown next to offending input.

## 5. UI Sanity
- [ ] Left nav: toggle between `paragraph | theme | issue`.
- [ ] Top nav: create theme, add issue, toggle link/classify.
- [ ] Main pane: virtualized sentence list performs < 50 ms/frame at 10k.
- [ ] Secondary pane shows linked sentences; no “navigate away” shortcuts.

## 6. CI Pipeline
- [ ] `ajv validate` mini.json.
- [ ] Smoke test: load stress-10k.json → render < 2 s, scroll hitch < 100 ms.
- [ ] Round-trip test included in CI workflow.

## 7. Sticky Watch-outs
- [ ] Undo/redo stays in-memory (not persisted).
- [ ] `splitterExceptions.json` is tested and doesn’t drift.
- [ ] Cross-doc view always uses split pane.
