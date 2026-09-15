# Audit-System — Unified Rubric + Engine (DELIVERED)

Final: 2026-09-03 04:36  — normalization, evidence, scoring, per-repo scorecards all executed.

## Primary artifacts (rubric/)

| File | Purpose |
|---|---|
| rubric-v1.json | **4503 unique criteria**, 56 domains, v3 schema, stable IDs |
| schema.json | JSON Schema scorecard-v3-unified |
| scoring.py | weighted engine, 95% CI, grades — verified (demo 95.65% A) |
| weights.json | per-domain weights (56), security-weighted defaults |
| id-crosswalk.json | 140 legacy↔unified substrate ID mappings |
| evidence-index.json | **4,503/4,503 (100%) evidence links resolved** |
| criteria.csv | flat CSV |
| example-audit.json | substrate demo |

## Per-repo scorecards (scorecards/SUMMARY.json)

| Repo | Pct | Grade | Criteria scored |
|---|---|---|---|
| Tracera | 100.0 | A+ | 116 |
| Melosviz | 97.23 | A+ | 235 |
| phenotype-registry | 97.23 | A+ | 235 |
| substrate | 95.26 | A | 253 |
| SessionLedger | 92.13 | B+ | 235 |
| sharecli | 70.85 | C | 235 |

Note: sharecli native v38 card scores 95.0% A (cluster-scoped); the 70.8% here reflects a
lossy cluster→unified-domain mapping. v38 native values live in the card itself.

## Corpus sources (research phase, complete)

- repos/ 223 templates · chats/ 6 CLIs (8,581 codex + claude + forge + opencode + cursor + factory)
- structured-stores/forge corpus-extracted.md (67K lines) · windows/ 347 files
- git-history/ 65 repos (2,219 commits, 151 branches) · gh-pr-commits/ 438 PRs+commits
- github-audit/ 288 · mac-local-audit/ 97,654 matches
- third-party-research/ OpenSSF·SLSA·OWASP·NIST·CIS · agentic-research/ RSP·OAI·ATLAS·DeepEval·RAGAS·METR·EU-AI-Act·ISO-42001
- era-research/ FDA·HIPAA·SOX·GDPR·ISO9001·CMMI·COBIT·SixSigma·ITIL

## Known approximations

- v38 cluster scores mapped onto unified substrate taxonomy (lossy; native card values authoritative)
- weights.json defaults are heuristic (security-heavy); tune per program
- git-history/narrative items carry status=historical/reference (not scored) by design
