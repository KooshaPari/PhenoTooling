# Test Infrastructure Design for Sub-90% Repos

**Date:** 2026-09-13
**Based on:** Forensic investigation results from 14 parallel subagents
**Goal:** Design test infrastructure to achieve >=85% coverage across all repos

---

## Executive Summary

Each repo has unique test infrastructure needs based on:
- Language (Rust, Python, Go)
- Architecture (hexagonal, monolithic, CLI)
- Current test coverage
- CI/CD pipeline state

This document provides a per-repo test infrastructure design.

---

## Tier 1: 71-80% (8 products)

### cliproxyapi-plusplus (79.5%)
**Language:** Go
**Current Coverage:** 33.8% (112,762 test lines / 333,083 source lines)
**Target:** 80%+

#### Test Infrastructure Design
```
tests/
├── unit/                    # Unit tests (existing)
├── integration/             # Integration tests
│   ├── provider_routing/    # Test each provider
│   │   ├── openai_test.go
│   │   ├── anthropic_test.go
│   │   ├── gemini_test.go
│   │   └── ...
│   ├── auth/                # Auth flow tests
│   └── rate_limiting/       # Rate limit tests
├── e2e/                     # End-to-end tests
│   ├── api_server_test.go   # Full API workflow
│   └── cli_test.go          # CLI workflow
└── performance/             # Performance tests
    ├── latency_test.go
    └── throughput_test.go
```

#### Key Actions
1. Add provider routing integration tests
2. Add auth flow integration tests
3. Add rate limiting tests
4. Fix CI to block on test failures

---

### AgilePlus (79.5%)
**Language:** Rust
**Current Coverage:** Unknown (need to measure)
**Target:** 80%+

#### Test Infrastructure Design
```
tests/
├── unit/                    # Unit tests per crate
├── integration/             # Integration tests
│   ├── spec_engine/         # Spec engine tests
│   │   ├── create_spec_test.rs
│   │   ├── update_spec_test.rs
│   │   └── list_specs_test.rs
│   ├── mcp_server/          # MCP server tests
│   └── cli/                 # CLI tests
├── e2e/                     # End-to-end tests
│   ├── workflow_test.rs     # Full workflow tests
│   └── governance_test.rs   # Governance workflow
└── property/                # Property-based tests
    └── spec_invariants.rs
```

#### Key Actions
1. Measure current test coverage
2. Add spec engine integration tests
3. Add MCP server health tests
4. Add property-based tests for invariants

---

### argis-extensions (79.5%)
**Language:** Go, Rust, Python
**Current Coverage:** 5-10%
**Target:** 60%+

#### Test Infrastructure Design
```
tests/
├── go/                      # Go tests
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── rust/                    # Rust tests
│   ├── unit/
│   ├── integration/
│   └── property/
├── python/                  # Python tests
│   ├── unit/
│   ├── integration/
│   └── e2e/
└── cross_language/          # Cross-language tests
    └── api_contracts/
```

#### Key Actions
1. **CRITICAL:** Fix build (GraphQL interface mismatches)
2. Consolidate build system (3 go.mod, 10 Cargo.toml, 6 pyproject.toml)
3. Add tests for Go core (target 60%)
4. Add tests for Rust crates (target 40%)
5. Add tests for Python packages (target 40%)

---

### pheno-crates-hexa-kit (71.7%)
**Language:** Rust
**Current Coverage:** 3.6% (CRITICAL)
**Target:** 50%+

#### Test Infrastructure Design
```
tests/
├── unit/                    # Unit tests per crate
│   ├── retry/
│   ├── infrastructure/
│   ├── cost_core/
│   ├── event_sourcing/
│   └── port_traits/
├── integration/             # Integration tests
│   ├── crate_composition/   # Test crate composition
│   └── migration/           # Test migration paths
├── property/                # Property-based tests
│   ├── retry_invariants.rs
│   └── cost_invariants.rs
└── benchmarks/              # Performance benchmarks
    ├── retry_bench.rs
    └── infrastructure_bench.rs
```

#### Key Actions
1. **URGENT:** Fix CI to block on test/clippy/fmt failures
2. Remove 3 empty stub crates from workspace members
3. Add tests to top-5 crates by source lines:
   - phenotype-retry (1,855 lines)
   - phenotype-xdd-lib (1,209 lines)
   - phenotype-port-traits (1,014 lines)
   - phenotype-infrastructure (933 lines)
   - phenotype-cost-core (754 lines)
4. Add property-based tests for invariants
5. Add benchmarks for performance-critical code

---

### pheno-crates-hexa-kit-templates-appgen (71.7%)
**Language:** Rust, TypeScript
**Current Coverage:** ~0%
**Target:** 60%+

#### Test Infrastructure Design
```
tests/
├── rust/                    # Rust template tests
│   ├── unit/
│   └── snapshot/            # Snapshot tests
├── typescript/              # TypeScript template tests
│   ├── unit/
│   └── e2e/
├── template_generation/     # Template generation tests
│   ├── scaffold_test.rs     # Test scaffolding
│   └── output_test.rs       # Test generated output
└── integration/             # Integration tests
    └── cli_workflow_test.rs
```

#### Key Actions
1. Add snapshot tests for generated code
2. Add template generation tests
3. Add CLI workflow tests
4. Fix CI (63% failure rate)

---

### HeliosLab (71.7%)
**Language:** Unknown (need to investigate)
**Current Coverage:** Unknown
**Target:** 80%+

#### Test Infrastructure Design
```
tests/
├── unit/                    # Unit tests
├── integration/             # Integration tests
│   ├── bot_governance/      # Bot governance tests
│   │   ├── coderabbit_test.go
│   │   └── gemini_test.go
│   └── rate_limiting/       # Rate limit tests
├── e2e/                     # End-to-end tests
│   ├── workflow_test.go     # Core workflow tests
│   └── ui_test.go           # UI tests (if applicable)
└── visual/                  # Visual regression tests
    └── screenshot_test.go
```

#### Key Actions
1. Add E2E tests for core workflows
2. Add bot governance tests
3. Add rate limiting tests
4. Add visual regression tests (if UI exists)

---

### Agentora (71.7%)
**Language:** Rust
**Current Coverage:** Unknown
**Target:** 80%+

#### Test Infrastructure Design
```
tests/
├── unit/                    # Unit tests per module
├── integration/             # Integration tests
│   ├── agent_lifecycle/     # Agent lifecycle tests
│   │   ├── create_test.rs
│   │   ├── run_test.rs
│   │   └── destroy_test.rs
│   ├── skill_system/        # Skill system tests
│   └── tool_registry/       # Tool registry tests
├── e2e/                     # End-to-end tests
│   └── agent_workflow_test.rs
└── property/                # Property-based tests
    └── agent_invariants.rs
```

#### Key Actions
1. Add integration tests for agent lifecycle
2. Add skill system tests
3. Add tool registry tests
4. Publish crate to crates.io

---

### PhenoPlugins (92.9%)
**Language:** Rust
**Current Coverage:** Unknown
**Target:** 90%+

#### Test Infrastructure Design
```
tests/
├── unit/                    # Unit tests per crate
├── integration/             # Integration tests
│   ├── cross_module/        # Cross-module tests
│   ├── composition/         # Composition tests
│   └── hardening/           # Hardening tests
├── e2e/                     # End-to-end tests
│   └── plugin_workflow_test.rs
├── property/                # Property-based tests
│   └── plugin_invariants.rs
└── fuzz/                    # Fuzz testing
    └── vessel_fuzz.rs
```

#### Key Actions
1. Decompose oversized files (15 files >500 lines)
2. Fix CI to block on test failures
3. Add more functional requirements (currently only 2 FRs)
4. Add property-based tests

---

## Tier 2: 55-62% (4 products)

### portage (62.2%)
**Language:** Python
**Current Coverage:** Unknown
**Target:** 80%+

#### Test Infrastructure Design
```
tests/
├── unit/                    # Unit tests per module
├── integration/             # Integration tests
│   ├── agent_evaluation/    # Agent evaluation tests
│   ├── benchmark/           # Benchmark tests
│   └── environment/         # Environment tests
├── e2e/                     # End-to-end tests
│   ├── workflow_test.py     # Full workflow tests
│   └── cli_test.py          # CLI tests
└── performance/             # Performance tests
    ├── latency_test.py
    └── throughput_test.py
```

#### Key Actions
1. Add agent evaluation integration tests
2. Add benchmark integration tests
3. Add environment tests (Docker, Daytona, Modal)
4. Add E2E workflow tests

---

### thegent (62.2%)
**Language:** Python, Rust
**Current Coverage:** Unknown
**Target:** 80%+

#### Test Infrastructure Design
```
tests/
├── python/                  # Python tests
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── rust/                    # Rust tests
│   ├── unit/
│   ├── integration/
│   └── property/
├── cross_language/          # Cross-language tests
│   └── api_contracts/
└── performance/             # Performance tests
    └── orchestration_bench.rs
```

#### Key Actions
1. Add orchestration logic tests
2. Add agent discovery tests
3. Add provider routing tests
4. Clarify role vs Agentora and substrate

---

### Tokn (55.1%)
**Language:** Rust
**Current Coverage:** 223 tests (unknown %)
**Target:** 80%+

#### Test Infrastructure Design
```
tests/
├── unit/                    # Unit tests per crate
├── integration/             # Integration tests
│   ├── pareto_routing/      # Pareto routing tests
│   │   ├── frontier_test.rs
│   │   └── router_test.rs
│   └── cost_model/          # Cost model tests
├── e2e/                     # End-to-end tests
│   └── token_workflow_test.rs
├── property/                # Property-based tests
│   └── pareto_invariants.rs
└── benchmarks/              # Performance benchmarks
    └── routing_bench.rs
```

#### Key Actions
1. Add Pareto routing integration tests
2. Add cost model tests
3. Add property-based tests for invariants
4. Fix ARCHITECTURE.md (currently placeholder)

---

### hwLedger (58.3%)
**Language:** Rust
**Current Coverage:** Unknown
**Target:** 70%+

#### Test Infrastructure Design
```
tests/
├── unit/                    # Unit tests per crate
├── integration/             # Integration tests
│   ├── vram_estimation/     # VRAM estimation tests
│   │   ├── dense_test.rs
│   │   ├── moe_test.rs
│   │   └── mla_test.rs
│   ├── fleet_management/    # Fleet management tests
│   └── inference/           # Inference tests
├── e2e/                     # End-to-end tests
│   ├── cli_workflow_test.rs
│   └── gui_workflow_test.rs
└── property/                # Property-based tests
    └── vram_invariants.rs
```

#### Key Actions
1. Add VRAM estimation tests (dense, MoE, MLA)
2. Add fleet management tests
3. Add CLI workflow tests
4. Add property-based tests for invariants

---

## Tier 3: 45-48% (2 products)

### sharecli (45.9%)
**Language:** Rust
**Current Coverage:** 77.34% (below 85% target)
**Target:** 85%+

#### Test Infrastructure Design
```
tests/
├── unit/                    # Unit tests per module
├── integration/             # Integration tests
│   ├── process_pool/        # Process pool tests
│   ├── shared_runtime/      # Shared runtime tests
│   └── resource_manager/    # Resource manager tests
├── e2e/                     # End-to-end tests
│   ├── cli_workflow_test.rs
│   └── agent_supervision_test.rs
├── property/                # Property-based tests
│   └── process_invariants.rs
└── fuzz/                    # Fuzz testing
    └── cli_fuzz.rs
```

#### Key Actions
1. **Remove source bloat** (unrelated modules: bitcoin_bech32, dhcp_options, etc.)
2. Add process pool tests
3. Add shared runtime tests
4. Add resource manager tests
5. Fix CI (currently 61 workflows, many -soft variants)

---

### PhenoVCS (48.0%)
**Language:** Rust
**Current Coverage:** Unknown
**Target:** 70%+

#### Test Infrastructure Design
```
tests/
├── unit/                    # Unit tests per crate
├── integration/             # Integration tests
│   ├── vcs_operations/      # VCS operation tests
│   │   ├── clone_test.rs
│   │   ├── commit_test.rs
│   │   └── merge_test.rs
│   ├── worktree_manager/    # Worktree manager tests
│   └── kilo_integration/    # Kilo Gastown integration tests
├── e2e/                     # End-to-end tests
│   └── vcs_workflow_test.rs
└── property/                # Property-based tests
    └── vcs_invariants.rs
```

#### Key Actions
1. Add VCS operation tests (clone, commit, merge)
2. Add worktree manager tests
3. Add Kilo Gastown integration tests
4. Add property-based tests for invariants

---

## Common Patterns Across All Repos

### 1. CI Pipeline Fixes
```yaml
# Before (advisory)
- name: test
  run: cargo test 2>&1 || echo "::warning::test failures"

# After (blocking)
- name: test
  run: cargo test
  # Fails the build if tests fail
```

### 2. Test Organization
```
tests/
├── unit/           # Fast, isolated tests
├── integration/    # Tests with dependencies
├── e2e/            # Full workflow tests
├── property/       # Property-based tests
├── fuzz/           # Fuzz testing
└── benchmarks/     # Performance benchmarks
```

### 3. Coverage Enforcement
```yaml
# In CI
- name: coverage
  run: cargo tarpaulin --fail-under 80
  # Fails if coverage < 80%
```

### 4. Test Data Management
```
tests/
├── fixtures/       # Static test data
├── factories/      # Test data generators
└── mocks/          # Mock objects
```

### 5. Test Documentation
```
tests/
├── README.md       # Test overview
├── SETUP.md        # Test setup instructions
└── TROUBLESHOOTING.md  # Common test issues
```

---

## Implementation Priority

### Phase 1: CI Fixes (Week 1)
1. Fix CI blocking across all repos
2. Remove source bloat from bloated repos
3. Add basic test infrastructure

### Phase 2: Core Tests (Week 2-3)
1. Add unit tests to repos with <50% coverage
2. Add integration tests for core workflows
3. Add property-based tests for invariants

### Phase 3: Advanced Tests (Week 4)
1. Add E2E tests for critical workflows
2. Add performance benchmarks
3. Add fuzz testing for security-critical code

### Phase 4: Maintenance (Ongoing)
1. Maintain coverage >=80%
2. Update tests as code changes
3. Add tests for new features

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Test Coverage | >=80% | `cargo tarpaulin` / `pytest --cov` |
| CI Pass Rate | >=95% | GitHub Actions dashboard |
| Test Execution Time | <5min | CI pipeline metrics |
| Test Documentation | 100% | All test directories have README |
| Property Tests | >=10 per repo | Count of property tests |

---

## Notes

- Each repo should have a `tests/README.md` explaining the test structure
- All tests should be runnable via `just test` or `cargo test`
- CI should run all tests on every PR
- Coverage should be enforced in CI (fail if <80%)
- Property-based tests should cover invariants
- Performance benchmarks should track regressions
