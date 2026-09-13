# Automated Code Review Workflow Orchestration — Design

| Field    | Value                                          |
| -------- | ---------------------------------------------- |
| Status   | DRAFT (AFK mode — awaiting operator review)    |
| Date     | 2026-09-09                                     |
| Author   | Forge / session `52a6ec6d-…-92e093a6d0c4`      |
| Audience | Operator (KooshaPari)                          |
| Spec of  | Resume of conversation `52a6ec6d-…-d0c4`        |

---

## 1. Goal

Build a fleet-wide automated code-review (CR) pipeline that:

1. **Retroactive**: scans historical PRs across the fleet, finds CR comments
   that were made and then ignored/dropped, and turns each ignored suggestion
   into a properly-scoped Issue + draft PR so an automated agent can resolve it.
2. **Proactive**: hooks every new PR so the same triage → issue → draft-PR loop
   runs the moment a CR comment is "ignored" (no follow-up commit within X
   days, no resolved-thread, or no author reply satisfying the comment).
3. **Provider rotation**: ships a smart CR-provider router — try the strongest
   free-tier provider first (default: CodeRabbit), back off cleanly on
   rate-limit, and rotate through a configured queue of providers
   (PR-Agent/CodiumAI, Greptile, Gemini Code Assist, Sourcery, Bito, etc.)
   so free-tier quota is never the gating factor.
4. **Local pre-CR gate**: extends the fleet-wide lefthook template
   (`phenotype-tooling-mergify/templates/lefthook.yml`) with a local
   pre-push CR-style check that catches the obvious stuff before any
   remote token is burned.
5. **Agent pickup**: every auto-created issue + draft PR carries an
   `auto-cr-resolve` label, and the existing `dispatching-parallel-agents`
   and `thegent` / `no-mistakes` agents recognize it and dispatch an
   implementer.

## 2. Non-Goals (explicit)

- Not replacing human review. The pipeline optimizes the *response* to CR
  suggestions, not the *generation* of them.
- Not a CR-provider itself. We orchestrate existing ones; we do not ship
  a model.
- Not a hosted SaaS. Everything runs in GitHub Actions + the operator's
  own runners + local machines.
- Not migrating the existing `no-mistakes` PR-body gate. That is
  orthogonal and already enforced; the new pipeline complements it.

## 3. Sub-Project Decomposition

The system splits into 6 shippable sub-projects. Each is independently
useful; together they form the orchestrator.

| #   | Sub-project             | Lifecycle                            | Sizing        |
| --- | ----------------------- | ------------------------------------ | ------------- |
| SP1 | `cr_roster` (catalog)  | Static config: providers, free tiers | XS — config   |
| SP2 | `cr-router`             | Provider rotation + rate-limit gate  | S — Go binary |
| SP3 | `cr-triage`             | Classify CR comments as actionable   | S — script    |
| SP4 | `cr-issue-forge`        | Comment → Issue + draft PR           | M — script    |
| SP5 | `cr-resolver` (pickup)  | Auto-dispatch to implementer agent   | M — glue      |
| SP6 | `cr-local-gate`         | Lefthook pre-push hook               | S — YAML      |

**SP1 catalog** is the spine — every other sub-project imports from it.
**SP2 router** is the thing the user explicitly named ("try CodeRabbit
first, when hit move to next"). **SP3 + SP4** are the retroactive and
proactive scan-and-create paths. **SP5** plugs into existing agent
dispatch. **SP6** is the local-side add-on to lefthook.

## 4. Architecture (Loose)

```
┌──────────────────────────────────────────────────────────────────────┐
│                        Remote: GitHub Fleet                          │
│                                                                      │
│   ┌─────────────────────────┐    ┌──────────────────────────────┐   │
│   │ .github/workflows/      │    │ .github/workflows/           │   │
│   │ cr-proactive.yml        │    │ cr-retroactive.yml           │   │
│   │ (PR open/synchronize)   │    │ (schedule: nightly + manual) │   │
│   └────────────┬────────────┘    └──────────────┬───────────────┘   │
│                │                                │                   │
│                ▼                                ▼                   │
│      ┌────────────────────────────────────────────────────┐         │
│      │           cr-triage → cr-issue-forge               │         │
│      │           (issue + draft PR, labeled               │         │
│      │            auto-cr-resolve)                        │         │
│      └────────────────────────┬───────────────────────────┘         │
│                               │                                     │
│      ┌────────────────────────▼───────────────────────────┐         │
│      │         cr-resolver (label-trigger)                │         │
│      │           → dispatch to existing                   │         │
│      │             thegent/codex/copilot agents           │         │
│      └────────────────────────────────────────────────────┘         │
│                                                                      │
│   ┌────────────────────────────────────────────────────┐             │
│   │  cr-router (sidecar runner OR Actions call)         │             │
│   │   providers: [coderabbit, pr-agent, greptile,       │             │
│   │               sourcery, gemini-code, bito]          │             │
│   │   state: per-provider daily-quota counter           │             │
│   └────────────────────────────────────────────────────┘             │
└──────────────────────────────────────────────────────────────────────┘
                                  │
                                  │  same providers invoked locally
                                  ▼
┌──────────────────────────────────────────────────────────────────────┐
│                        Local: Developer Machine                      │
│                                                                      │
│   lefthook pre-push                                                  │
│     ├─ editorconfig + yaml/json/toml  (already)                      │
│     ├─ secrets (trufflehog)            (already)                     │
│     ├─ file-size gate                  (already)                     │
│     ├─ ★ cr-local-gate (NEW)                                         │
│     │     ├─ prettier/black/gofmt --check                            │
│     │     ├─ eslint/clippy w/ project rules                          │
│     │     └─ cr-router --local (opt-in: local-only CR suggestion)     │
│     └─ no-mistakes verify.py            (already via pre-push)       │
└──────────────────────────────────────────────────────────────────────┘
```

## 5. Approach Options (and Trade-offs)

### Option A — Pure-GitHub-Actions + gh CLI (RECOMMENDED)
- **Pros**: zero new infra; reuses existing `gh` + Actions minutes; easy to
  inspect runs; mirrors `no-mistakes/` pattern.
- **Pros**: lower blast-radius per repo (each repo gets its own workflow).
- **Cons**: provider secrets fanned out per repo (mitigated via GH Org
  secret store).
- **Cons**: nightly retroactive scan needs a central host. Mitigation:
  pick one repo (`phenotype-tooling-mergify`) as the "fleet CR concierge"
  and schedule its workflow with a curated org-wide PAT.

### Option B — Standalone service (small Go binary on a runner)
- **Pros**: cleaner provider rotation state (in-memory + durable Redis).
- **Pros**: single binary, fewer moving parts.
- **Cons**: another service to deploy; replication of `no-mistakes/cmd`
  pattern; more to maintain.

### Option C — Cron + n8n / Temporal
- **Pros**: visual orchestration.
- **Cons**: yet another system to host; not aligned with existing fleet
  tooling.

**Selection**: Option **A**. It reuses the proven `no-mistakes/`
pattern, every primitive we need already exists in Actions + `gh`,
and the central-concierge-repo model lets the fan-out stay small.

## 6. Decisions to Confirm (operator)

> The operator is AFK. The defaults below were picked to be the
> conservative choice in each case. Each line is editable; if any are
> wrong on return, fix the doc and re-run the brainstorm, no rebuild needed.

| #  | Decision                                            | Default                | Why                                                                |
| -- | --------------------------------------------------- | ---------------------- | ------------------------------------------------------------------ |
| D1 | Roster repo (where SP1 lives & cron lives)          | `phenotype-tooling-mergify` | Same home as `lefthook.yml` template, matches "fleet-wide" intent |
| D2 | Default primary provider                           | CodeRabbit             | User named it first in brief                                      |
| D3 | Provider queue (priority order)                    | CodeRabbit → PR-Agent/CodiumAI → Gemini Code Assist → Sourcery → Greptile → Bito | Free-tier first, self-hostable second |
| D4 | Quota rotation unit                                | Per-day, per-provider  | Matches all listed providers' reset windows                        |
| D5 | Triage threshold ("ignored comment")                | No follow-up commit AND no resolved-thread AND no author reply after 7 days | Conservative — matches GitHub's own "Stale" rule |
| D6 | Auto-merge for resolver                             | NO. Always human PR review | Existing rule; do not weaken                                      |
| D7 | Languages to scan CR comments for                  | All (any PR)           | We don't gate yet                                                 |
| D8 | Local lefthook stage                               | pre-push (not pre-commit) | Matches existing template's heaviest hook (cargo-deny, audits)   |
| D9 | Reuses existing repo for first run                 | yes — `phenotype-tooling-mergify` | Cheapest blast-radius                                              |
| D10| Notification path                                  | Issue + draft PR only. No email. | Low-noise; aligns with "agents pick up" pattern |

## 7. Assumptions Made (transparent defaults — operator can flip)

- The fleet is GitHub-hosted, not self-hosted GHE. (True today; no GHE
  remote detected.)
- We trust third-party CR providers with read-access to PR diffs. (True
  today; CodeRabbit / Greptile / Sourcery already used across fleet.)
- The `auto-cr-resolve` label is unused today. (Verified by search
  across the workspace during exploration.)
- The existing `phenotype-tooling-mergify/.github/workflows/` does not
  yet contain a CR-proactive workflow (verified — only `reusable-quality-gate.yml`-related
  files and templates).
- PATs for the concierge repo have `repo`, `read:org`, `workflow` —
  already present on the operator's `gh` CLI auth.

## 8. Phased Delivery (suggested)

| Phase | Scope                                             | Validates                |
| ----- | ------------------------------------------------- | ------------------------ |
| P0    | SP1 catalog + SP6 lefthook extension (no remote)  | Reusable scaffolding     |
| P1    | SP2 router, dry-run only                         | Provider rotation path   |
| P2    | SP3 triage, retroactive, 1 repo (the concierge)  | Comment-classification  |
| P3    | SP4 issue-forge, label, 1 repo                   | Issue + draft PR shape   |
| P4    | SP5 resolver pickup, dry-run, 1 repo             | Agent picks up           |
| P5    | Proactive workflow, all repo templates published  | Fleet-wide enforcement   |
| P6    | Nightly schedule, dashboards, Slack-free summary  | Operational              |

P0–P3 are shippable in one work session. P4 needs an agent session.
P5–P6 are fleet-rollout + ops.

## 9. Out-of-Scope for This Design (parking lot)

- Hosting our own CR model.
- Slack / Discord ping on rotation fallback.
- Per-developer vs per-org secret scoping.
- GUI dashboard (a `gh`-friendly text report is enough for now).

## 10. Definition of Done (this design)

- [ ] Operator confirms or edits the **D1–D10** table.
- [ ] Spec self-review (placeholders, consistency) is run — see
      `10-b. Self-review checklist`.
- [ ] `writing-plans` skill is invoked to produce a concrete
      implementation plan out of P0.
- [ ] No code is written before plan approval.

### 10-b. Self-review checklist

- [ ] No `TODO` / `TBD` / `???` placeholders.
- [ ] All scope references match section names.
- [ ] Every primitive (CR suggestion, Issue, draft PR, label) maps to
      a GitHub API concept (review_comment, issue, pull_request,
      issue_labels).
- [ ] Each sub-project (SP1–SP6) has a one-sentence verb that a
      sub-agent could be tasked with.
- [ ] Phases are sequenced so each phase leaves the system in a
      runnable state (no half-built branch).
- [ ] No new infra introduced (Option A confirmed).
- [ ] No irreversible action (push, publish, delete) appears in any
      default step — operator is required to opt-in to the first
      retroactive run.
