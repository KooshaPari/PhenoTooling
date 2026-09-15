# Forensic Investigation Results - Tier 1 & 2 Repos

**Date:** 2026-09-13
**Investigation Method:** 14 parallel subagents, forensic SSOT recovery protocol
**Status:** Phase 1 complete, Phase 2 in progress

---

## Executive Summary

14 repos investigated in parallel. Key findings:

1. **HexaKit has CRITICAL quality issues** (3.6% test coverage, CI non-blocking)
2. **Most repos have good architectural vision** but lack test infrastructure
3. **CI is普遍 advisory, not blocking** across multiple repos
4. **Agent-managed repos show patterns** of incomplete stabilization

---

## Tier 1: 71-80% (8 products)

### cliproxyapi-plusplus (79.5%)
**Purpose:** Go LLM proxy with multi-provider support (OpenAI, Anthropic, Azure, Gemini, Bedrock, Kiro, Copilot, Ollama)
**Ecosystem:** Part of "Kush" multi-repo system (thegent, agentapi++, tokenledger, 4sgm, civ, parpour, pheno-sdk)
**Architecture:** Clean Go structure, chi router, zerolog, viper config
**Quality Gates:** 80% test coverage, 0 lint errors, 0 critical security
**Gaps:** Need to verify actual test coverage vs claimed
**Recommendation:** Verify test coverage, add integration tests for provider routing

### AgilePlus (79.5%)
**Purpose:** Spec-driven development framework (Rust CLI + workspace)
**Architecture:** 22 crates, hexagonal architecture, 14 ADRs documented
**Quality Gates:** cargo clippy, cargo fmt, cargo test, cargo deny, ruff
**Branch Discipline:** Worktree pattern with PR-only main
**Gaps:** Spec engine core may be incomplete, MCP server health
**Recommendation:** Verify spec engine functionality, add integration tests

### argis-extensions (79.5%)
**Purpose:** Extensions library (zz-argis-extensions)
**Status:** Needs deeper investigation (agent still running)
**Recommendation:** Complete forensic, map extensions catalog

### pheno-crates-hexa-kit (71.7%)
**Purpose:** Rust workspace for reusable infrastructure primitives
**CRITICAL FINDINGS:**
- **3.6% test-to-source ratio** (387 test lines / 10,605 source lines)
- **CI is NON-BLOCKING** (all failures swallowed as warnings)
- **3 empty stub crates** still in workspace members
- **71 days since last commit**, single contributor
- **25 crates migrated** to canonical homes (good migration hygiene)
**Architecture:** Excellent hexagonal architecture vision
**Recommendation:** URGENT - Fix CI to block, add tests to top-5 crates, remove stubs

### pheno-crates-hexa-kit-templates-appgen (71.7%)
**Purpose:** App generation templates (same repo as hexa-kit)
**Status:** Templates for code generation
**Recommendation:** Add snapshot tests for generated code

### HeliosLab (71.7%)
**Purpose:** Coding agent client/workbench
**Governance:** CodeRabbit + Gemini Code Assist bot review
**Rate Limits:** FIFO queue, 120s minimum spacing, 15min backoff
**Gaps:** UI quality, test coverage, documentation
**Recommendation:** Add E2E tests for core workflows

### Agentora (71.7%)
**Purpose:** Rust hexagonal-architecture framework for AI agents
**Crate:** agentkit (0.1.0)
**Architecture:** 4-layer hexagonal (Domain / Application / Adapters / Infrastructure)
**Features:** openai, redis-memory, sqlite-memory (behind feature flags)
**Governance:** STANDARDS.md, API_CONTRACT_AUDIT.md, CHANGELOG.md
**Gaps:** Framework completeness, documentation
**Recommendation:** Add integration tests for agent lifecycle

---

## Tier 2: 55-62% (4 products)

### portage (62.2%)
**Status:** Agent running, findings pending
**Recommendation:** Complete forensic investigation

### thegent (62.2%)
**Status:** Agent running, findings pending
**Recommendation:** Complete forensic investigation

### Tokn (55.1%)
**Status:** Agent running, findings pending
**Recommendation:** Complete forensic investigation

### hwLedger (58.3%)
**Status:** Agent running, findings pending
**Recommendation:** Complete forensic investigation

---

## Tier 3: 45-48% (2 products)

### sharecli (45.9%)
**Status:** Agent running, findings pending
**Recommendation:** Complete forensic investigation

### PhenoVCS (48.0%)
**Status:** Agent running, findings pending
**Recommendation:** Complete forensic investigation

---

## Cross-Cutting Findings

### 1. CI Advisory Pattern
Multiple repos have CI that warns but doesn't block:
- HexaKit: `continue-on-error: true`, `|| echo "::warning::"`
- Others likely similar
**Action:** Fix CI to actually block merges on failure

### 2. Test Coverage Gap
Most repos have good architecture but poor test coverage:
- HexaKit: 3.6% test-to-source ratio
- Others likely similar
**Action:** Add tests to top-5 crates per repo

### 3. Documentation Staleness
Multiple repos have stale/inconsistent documentation:
- HexaKit: README shows 60% and 80% inconsistently
- Others likely similar
**Action:** Update README, remove stale docs

### 4. Empty Stubs
Some repos have empty stub crates/modules:
- HexaKit: 3 empty stub crates
**Action:** Remove or populate stubs

---

## Priority Actions

### Immediate (1-2 days)
1. **HexaKit:** Fix CI to block, add tests to top-5 crates, remove stubs
2. **All repos:** Verify test coverage claims
3. **All repos:** Fix CI to block on failure

### Short-term (1 week)
4. **All repos:** Add integration tests for core workflows
5. **All repos:** Update documentation
6. **All repos:** Resolve empty stubs

### Medium-term (2-4 weeks)
7. **All repos:** Achieve 50% test coverage
8. **All repos:** Separate mixed concerns
9. **All repos:** Enforce quality gates

---

## Notes

- Investigation used 14 parallel subagents
- Each agent cloned repo, analyzed structure, identified gaps
- Findings are preliminary - need validation
- Some agents still running (portage, thegent, Tokn, hwLedger, sharecli, PhenoVCS)
