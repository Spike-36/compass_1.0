# Compass MVP — Sentence → Theme → Issue Mapper (macOS Swift App)

---

## Problem

Lawyers and other legal services professionals often deal with pleadings full of numbered paragraphs, each containing multiple sentences.
The real work lies in analysing sentences — which are admitted, denied, or disputed — and then connecting them to the legal issues the court must decide.

Current tools (Word, PDF) make this **slow, manual, and inconsistent**.

---

## MVP Concept

A lightweight **macOS desktop app** (built in Swift with AppKit/SwiftUI) that lets users take pleadings (or other structured text) and:

1. Classify sentences as admitted, not admitted, or disputed.
2. Add descriptive labels to paragraphs/themes to index and organise.
3. Link connected sentences (e.g. claim ↔ response).
4. Group related sentences into named issues.
5. Switch between paragraph, theme, and issue views for structured analysis.

➡️ MVP = **dynamically re-viewing pleadings** in three modes:

* **Sentence view**
* **Paragraph / Theme view**
* **Issue map**

---

## Core Features

### Sentence Classification

* Sentences are the atomic unit.
* Each sentence carries a status: `admitted` | `not_admitted` | `disputed` | `unset`.
* Sentences may be labelled for quick filtering.

### Sentence Linking

* Connect sentences (claim → response, support → counter, etc.).
* Visual cues: arrows, colour coding, side-by-side.
* macOS UI: drag-to-link or context menu.

### Paragraph / Theme Grouping

* Pleading paragraphs act as **themes**.
* Each theme groups the sentences it contains.
* Users may optionally add a descriptive name for a paragraph/theme (“Damages”, “Causation”).
* One level of sub-themes allowed for light organisation.
* Sentences can belong to only one theme (their paragraph).

### Issue Mapping

* Issues are higher-level questions the court must decide.
* Issues are composed of sentences drawn from across themes.
* A sentence may contribute to multiple issues.
* Issues provide the analytical lens, separate from document structure.

---

## Modes of Use

* **Mode A: Linking** – connect claim/response sentences.
* **Mode B: Grouping** – view paragraphs (themes) with optional descriptive names.
* **Mode C: Classification** – mark each sentence admitted/denied/disputed.
* **Mode D: Issue Mapping** – gather sentences into issues, regardless of paragraph.

---

## User Flow

1. Import text → split into paragraphs → split into sentences.

   * Input: copy-paste text, drag-drop a `.txt`/`.rtf`/`.docx`.
2. Assign sentence status (admitted / denied / disputed / unset).
3. Optionally label paragraphs/themes for navigation.
4. Link relevant sentences.
5. Group sentences into issues.
6. Toggle between views:

   * **Paragraph view** – original pleading structure.
   * **Theme view** – paragraphs with user labels.
   * **Issue map view** – issues with contributing sentences.

---

## macOS-Specific UI

* **Left sidebar** – switch between views (paragraph, theme, issue).
* **Toolbar (native macOS)** – actions: create theme, add sub-theme, map issue, toggle modes.
* **Main panel** – sentence blocks with inline controls for linking, labelling, classification.
* **Menus/shortcuts** – support standard macOS keyboard shortcuts (⌘N new issue, ⌘L link sentences, etc.).
* **Multi-window support** – allow opening multiple pleadings side by side.


