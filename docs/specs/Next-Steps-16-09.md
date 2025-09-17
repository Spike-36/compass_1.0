# 🔜 Next Steps (16 Sept)

## 1. Repo hygiene
- Create `schema/` → drop in `v1.4.2.json`.
- Create `tools/` → put `gen_fixtures.py`.
- Create `fixtures/` → check in `mini.json` + `stress-10k.json` (generated, not hand-edited).

## 2. Database migration
- Edit `db/schema.sql`:
  - Drop old unique constraint on paragraph.
  - Add `uidx_paragraph_live` partial unique (WHERE `deletedAt IS NULL`).
  - Add link constraints (claim_response inverse trigger).
- Run `init_db.py` → verify migrations apply cleanly to `compass.db`.

## 3. Swift integration guards
- In `IDSpec.swift`: enforce sentence ID regex (`doc-para-sent`).
- In `DocumentIdentity.swift`: add timestamp validator (`Z`-suffix).
- Wrap updates in optimistic concurrency (`updatedAt` check → 409 on mismatch).

## 4. UI scaffolding
- **Left nav**: mode toggles (`paragraph | theme | issue`).
- **Top nav**: create theme, add issue, toggle link/classify.
- **Main pane**: virtualized sentence list (status toggle, labels, link markers).
- **Secondary pane**: linked sentence display/back stack (no “just navigate away” shortcuts).

## 5. CI pipeline
- Add step: `ajv validate -s schema/v1.4.2.json -d fixtures/mini.json`.
- Add stress smoke: load `stress-10k.json` into viewer; assert render `< 2s`, scroll hitch `< 100ms`.
- Round-trip test: import → export → byte-compare (ignore `updatedAt`).

---

## ✅ Deliverables by end of week
- Schema + fixtures committed.
- Migration applied & tested on local `compass.db`.
- Swift guards live.
- Barebones UI scaffold (even without polish).
- CI green with mini + stress fixtures.

---

## ⚠️ Sticky watch-outs
1. Undo/redo = in-memory only (never persist logs).
2. Splitter exceptions JSON = first-class test input (don’t let it drift).
3. Perf = 10k sentences minimum baseline.
4. Cross-doc = split pane required, not optional.
