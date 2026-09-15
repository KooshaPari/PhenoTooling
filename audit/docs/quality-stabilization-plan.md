# Quality-Stabilization Plan for Sub-90% Repos

**Date:** 2026-09-13 (refined 2026-09-13)
**Scope:** 14 products scoring below 90%
**Priority:** Quality/stabilization first, code writing only if needed for stabilization
**Protocol:** Forensic SSOT recovery for agent-managed repos
**Status:** Forensic investigation complete for all repos (13/14, hwLedger still running)

---

## Executive Summary

14 products score below 90%. These repos have been in agent dev loops for months. The approach is:
1. **Investigate** what each repo actually is (forensic protocol)
2. **Stabilize** test infrastructure, CI, documentation
3. **Plan** quality improvements before any feature work
4. **Execute** only after research/plan is optimal

### Cross-Cutting Findings from Forensic Investigation
- **CI Advisory Pattern:** Multiple repos have CI that warns but doesn't block merges
- **Test Coverage Gap:** Most repos have good architecture but poor test coverage (HexaKit: 3.6%)
- **Documentation Staleness:** Multiple repos have stale/inconsistent documentation
- **Empty Stubs:** Some repos have empty stub crates/modules

---

## Tier 1: 71-80% (8 products) - Good Foundation, Targeted Gaps

### cliproxyapi-plusplus (79.5%)
**Status:** Go LLM proxy with multi-provider support
**Findings:**
- Part of "Kush" multi-repo system (thegent, agentapi++, tokenledger, 4sgm, civ, parpour, pheno-sdk)
- Clean Go structure, chi router, zerolog, viper config
- 8 providers: OpenAI, Anthropic, Azure, Gemini, Bedrock, Kiro, Copilot, Ollama
- Quality gates: 80% test coverage, 0 lint errors, 0 critical security
**Plan:**
1. Verify actual test coverage vs claimed
2. Add integration tests for provider routing
3. Verify Docker setup
4. Check documentation currency

### AgilePlus (79.5%)
**Status:** Spec-driven development framework (Rust CLI + workspace)
**Findings:**
- 22 crates in workspace, hexagonal architecture
- 14 ADRs documented
- Quality gates: cargo clippy, cargo fmt, cargo test, cargo deny, ruff
- Branch discipline: worktree pattern with PR-only main
- Dino integration (submodule)
**Plan:**
1. Verify spec engine functionality
2. Add integration tests for spec engine
3. Verify MCP server health
4. Update documentation

### argis-extensions (79.5%)
**Status:** Extensions library (zz-argis-extensions)
**Findings:** Agent still running, findings pending
**Plan:**
1. Complete forensic investigation
2. Map extensions catalog
3. Add tests for each extension
4. Update documentation

### pheno-crates-hexa-kit (71.7%)
**Status:** Rust workspace for reusable infrastructure primitives
**CRITICAL FINDINGS:**
- 3.6% test-to-source ratio (387 test lines / 10,605 source lines)
- CI is NON-BLOCKING (all failures swallowed as warnings)
- 3 empty stub crates still in workspace members
- 71 days since last commit, single contributor
- 25 crates migrated to canonical homes (good migration hygiene)
**Plan:**
1. URGENT: Fix CI to block on test/clippy/fmt failures
2. Remove empty stubs from workspace members
3. Add tests to top-5 crates by source lines
4. Achieve 50% test coverage on active crates
5. Clean up stale documentation
6. Resolve phenotype-security-aggregator exclusion

### pheno-crates-hexa-kit-templates-appgen (71.7%)
**Status:** App generation templates
**Findings:** Same repo as hexa-kit, templates for code generation
**Plan:**
1. Add snapshot tests for generated code
2. Ensure templates compile
3. Update template catalog
4. Document generation guide

### HeliosLab (71.7%)
**Status:** Coding agent client/workbench
**Findings:**
- Review bot governance (CodeRabbit + Gemini Code Assist)
- Rate-limit discipline: FIFO queue, 120s minimum spacing, 15min backoff
- Bot review retrigger protocol documented
**Plan:**
1. Add E2E tests for core workflows
2. Ensure build passes
3. Add visual regression tests
4. Update user guide and architecture docs

### Agentora (71.7%)
**Status:** Rust hexagonal-architecture framework for AI agents
**Findings:**
- Crate: agentkit (0.1.0)
- 4-layer hexagonal (Domain / Application / Adapters / Infrastructure)
- Feature flags: openai, redis-memory, sqlite-memory
- Governance: STANDARDS.md, API_CONTRACT_AUDIT.md, CHANGELOG.md
**Plan:**
1. Add integration tests for agent lifecycle
2. Verify SDK builds and examples
3. Update SDK reference
4. Document getting started guide

---

## Tier 2: 55-62% (4 products) - Partial Maturity, Significant Work

### portage (62.2%)
**Status:** Harbor framework - AI agent evaluation and optimization
**Findings:**
- Python monorepo with CLI, docs website, and results viewer
- Agent evaluation: Run evaluations against benchmark tasks
- Benchmark support: SWE-Bench, Terminal-Bench, Aider Polyglot
- Parallel execution via Daytona, Modal, E2B
- RL optimization for agent training
- Built-in agents: claude-code, openhands, aider, codex, etc.
**Plan:**
1. Verify test coverage and CI status
2. Add integration tests for core evaluation workflows
3. Ensure Docker environment works
4. Update documentation

### thegent (62.2%)
**Status:** Python agent orchestration framework
**Findings:**
- Core: Python (src/thegent/)
- CLI: Typer, Rich
- Agent Integration: BlackBoxProxy, Agent Discovery & Registration
- Dotfiles management
- Quality gates: ruff check, ruff format, pytest
- Max function length: 40 lines, cognitive complexity ≤ 15
**Plan:**
1. Verify test coverage and CI status
2. Add integration tests for orchestration logic
3. Ensure agent discovery works
4. Update documentation

### Tokn (55.1%)
**Status:** Token pricing governance system for AI agents
**Findings:**
- Rust workspace with Pareto routing sub-system
- Crates: pareto-rs (cost modeling), tokenledger (routing)
- Pareto frontier optimization for cost/capability tradeoffs
- AgilePlus mandate for work tracking
- Worktree pattern with PR-only main
**Plan:**
1. Verify Pareto routing implementation
2. Add unit tests for cost modeling
3. Ensure token operations work
4. Update API documentation

### hwLedger (58.3%)
**Status:** LLM capacity planner + fleet ledger + desktop inference runtime
**Findings:**
- Pre-alpha Phase 0 (25% progress)
- Rust core + per-OS native GUIs (SwiftUI, WinUI 3, Qt 6, Slint)
- 11-crate workspace: hwledger-core, -arch, -ingest, -probe, -inference, -ledger, -fleet-proto, -agent, -server, -cli, -ffi
- Substrate dependencies: pheno-capacity (VRAM estimation)
- Features: VRAM planning, fleet management, inference runtime, audit logging
- Status: SCAFFOLD (mostly docs/scaffold)
- Blocked on Apple Developer certificate renewal for macOS DMG
**Plan:**
1. Verify Rust workspace builds and tests pass
2. Add unit tests for core VRAM estimation logic
3. Ensure CLI works end-to-end
4. Update documentation

---

## Tier 3: 45-48% (2 products) - Early Stage, Major Gaps

### sharecli (45.9%)
**Status:** Shared CLI process manager for multi-project agent orchestration
**Findings:**
- Rust (edition 2021)
- Process management, pooling, resource limits
- Architecture: ProcessPool, SharedRuntime, ResourceManager
- Dependencies: substrate, sysinfo, tokio
- FR-traceable tests (FR-001..FR-005)
- Test-first mandate for new modules
- Quality gates: fmt-check, lint, test, FR-reference in PR body
- Claim-lock protocol for parallel agents
**Plan:**
1. Verify test coverage and CI status
2. Add tests for FR-003..FR-005 (currently missing)
3. Ensure process pool works correctly
4. Update documentation

### PhenoVCS (48.0%)
**Status:** Rust workspace for version control primitives
**Findings:**
- Hexagonal architecture (Ports & Adapters)
- Crates: pheno-vcs-core, worktree-manager
- Kilo Gastown integration for agent work delegation
- Workflow: gt_prime → work → gt_checkpoint → gt_done
- Domain layer with ZERO external dependencies
- Git operations via subprocess (not git2 crate)
**Plan:**
1. Verify VCS operations work
2. Add integration tests for worktree management
3. Ensure Kilo integration works
4. Update documentation

---

## Execution Protocol

### Phase 1: Research (1-2 days per repo)
1. Forensic investigation following prompts/03-forensic-ssot-recovery.md
2. Identify actual product state vs claims
3. Map capabilities, regressions, gaps
4. Document findings in session docs

### Phase 2: Planning (0.5-1 day per repo)
1. Prioritize quality improvements
2. Design test infrastructure
3. Plan CI improvements
4. Design documentation structure

### Phase 3: Stabilization (2-3 days per repo)
1. Add/fix tests to meet >=85% coverage
2. Fix CI to pass all checks
3. Add critical documentation
4. Establish baseline metrics

### Phase 4: Verification (0.5 day per repo)
1. Run full test suite
2. Verify CI passes
3. Check documentation completeness
4. Update scorecards

---

## WIP Limits
- **Max 3 repos** in active work simultaneously
- **Max 2 repos** in forensic investigation simultaneously
- **1 repo** in stabilization at a time (full attention)

## Success Criteria
- All sub-90% repos: >=85% test coverage
- All sub-90% repos: CI passing
- All sub-90% repos: Critical documentation present
- All sub-90% repos: Forensic investigation complete
- Updated scorecards reflecting improvements

---

## Notes
- **No code writing** unless needed for stabilization (test fixes, CI fixes)
- **No feature work** until quality baseline established
- **Over-plan, research, engineer** before any execution
- **Assume every repo has been stuck in agent dev loops for months**
- **Case study/pilot approach** for each repo
