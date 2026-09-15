# Scorecard generator provenance

**Scope:** local evidence only; this handoff records historical provenance, not current lineage.

## VERIFIED

- The preserved session `chats/codex/sessions/01a0606a-b33a-7e52-934a-7774d75843a2.jsonl` records an execution at `2026-09-03T11:32:54.023Z` that created and ran `/tmp/emit_repo_scorecards.py`.
- The generator reads `rubric/rubric-v1.json` and `CONSOLIDATED_RUBRIC.json`.
- It scans `repos/*/audit_scorecard.json`, retaining cards with `pillars_evaluated` entries and collecting each entry's domain, status, and title.
- For each domain, it selects `source == "substrate-v3"` unified criteria, sorts those criteria by lower-cased title, and pairs statuses to criteria by positional `zip`.
- The pairing is count-min only: there is no length check and no title check. Accepted statuses are `satisfied`, `partial`, and `missing`.
- It invokes `rubric/scoring.py`, writes `scorecards/<repo>-audit.json`, and writes `scorecards/SUMMARY.json`.

## HISTORICAL

- This proves that generator behavior and its output path existed in the preserved 2026-09-03 session. It does not prove that the current scorecards were produced by that run, or that any current card has reviewed conversion lineage.
- The generator's `orig = ... CONSOLIDATED_RUBRIC.json` read is provenance context only; the shown mapping and scoring use `rubric-v1.json`.

## Implications for cards

- **Tracera — HISTORICAL/UNKNOWN:** A Tracera scorecard emitted by this path would be a positional substrate-v3 crosswalk, not a title-validated conversion of Tracera's native criteria. Local evidence records the candidate native card as 96 `L#` rows with 0–5 scores and a claimed 435/435, while the unified input has 47 criteria and 116 rubric rows; no reviewed transformation tying them to unified IDs is established (`audits/2026-09-07/dry_run/SOURCE-PROVENANCE.md`). Therefore its score is not evidence that Tracera's native criteria were individually assessed.
- **Substrate — HISTORICAL/UNKNOWN:** The preserved native card records 140 pillars, 126 satisfied, 14 partial, and 95.0%; a generated `scorecards/substrate-audit.json` is a separate positional/unified result. Local evidence records 140 unified input rows, 127 unique IDs, 13 duplicate-ID groups, and distinct native versus unified percentages. Do not treat the generated card as a validated restatement of the native Substrate card.

## BLOCKED

- Current lineage from any present `scorecards/*` artifact back to a specific generator run, source card revision, and reviewed title/ID mapping is **BLOCKED** by this evidence. No current regeneration, mutation, network access, git operation, or remote operation was performed.
