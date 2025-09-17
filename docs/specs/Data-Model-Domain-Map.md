# Compass MVP — Data Model & Domain Map

> macOS app for analysing pleadings.  
> Lawyers work from pleadings full of numbered paragraphs. The real analysis happens at sentence level (what’s admitted / denied / disputed) and by linking claims ↔ responses into issues the court must decide. Word/PDF workflows are slow and fragile — especially when pleadings are amended (new words, sentences, or paragraphs inserted/deleted).

---

## Entities

### Sentence
- **id**: unique identifier (`${docId}-${para}-${sentIndex}`)
- **text**: the sentence string
- **labels**: array of descriptive labels (optional, ≤10, ASCII ≤80)
- **links**: array of `Link.id` references
- **status**: enum: `agreed | unknown | disputed | unset`
- **themeId**: the paragraph/theme this sentence belongs to

### Link
- **id**
- **sourceSentenceId**
- **targetSentenceId**
- **type**: enum (`claim-response | supports | contradicts | cites`)
- Directional, no self-links, no inverse claim-response

### Theme (Paragraph)
- **id**
- **name**: optional, user-defined descriptive label
- **sentenceIds**: array of `Sentence.id`s (each sentence belongs to exactly one theme)

### Issue
- **id**
- **name**: user-defined string
- **sentenceIds**: array of `Sentence.id`s connected to this issue  
  (a sentence may belong to multiple issues)

---

## Relationships
- A **Sentence** must belong to exactly one **Theme** (its paragraph).
- A **Sentence** may link to multiple other sentences (many ↔ many via Link).
- A **Sentence** may belong to multiple **Issues** (cross-cutting).
- A **Theme** is structural, inherited from the pleading’s paragraph.
- An **Issue** spans across themes/paragraphs by grouping sentences.

---

## Rules & Constraints
- Sentences can exist unlinked but must always belong to one Theme.
- Labels are flexible and user-defined.
- Issues are optional and analytical — they may cut across many themes.
- Status (`agreed | unknown | disputed | unset`) is stored at the Sentence level.
- No nesting required: paragraphs are flat, but themes may be named.
- Renumbering support is required when pleadings are amended (insertions/deletions of words, sentences, or paragraphs).

---

## Example JSON (Tiny)

```json
{
  "sentences": [
    {
      "id": "s1",
      "text": "The claimant alleges breach of contract.",
      "labels": ["Claim", "Contract"],
      "links": ["l1"],
      "status": "disputed",
      "themeId": "t1"
    },
    {
      "id": "s2",
      "text": "The defendant denies breach of contract and asserts compliance.",
      "labels": ["Response", "Contract"],
      "links": ["l1"],
      "status": "disputed",
      "themeId": "t1"
    },
    {
      "id": "s3",
      "text": "Both parties agree the contract was signed on 1 Jan 2020.",
      "labels": ["Agreed Fact", "Contract Date"],
      "links": [],
      "status": "agreed",
      "themeId": "t2"
    }
  ],
  "links": [
    {
      "id": "l1",
      "sourceSentenceId": "s1",
      "targetSentenceId": "s2",
      "type": "claim-response"
    }
  ],
  "themes": [
    {
      "id": "t1",
      "name": "Breach of Contract",
      "sentenceIds": ["s1", "s2"]
    },
    {
      "id": "t2",
      "name": "Contract Formation",
      "sentenceIds": ["s3"]
    }
  ],
  "issues": [
    {
      "id": "i1",
      "name": "Contractual Obligations",
      "sentenceIds": ["s1", "s2", "s3"]
    }
  ]
}
