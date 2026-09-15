# CLAUDE.md - Audit System Project

## Project Overview
Agent-operated product evaluation system for the KooshaPari portfolio (146 repositories). Inventories repos, measures behavior against a 3,598-criteria rubric, discovers gaps, and produces auditable scorecards.

## Canonical Context
**Read AGENTS.md first** - it contains the consolidated portfolio context, execution protocol, evaluation methodology, and quality gates.

## Quick Reference

### CLI Commands
```bash
python3 eval.py run              # Run evaluation
python3 eval.py dashboard        # Generate dashboard
python3 check_scores.py          # Check scores against threshold
python3 api.py                   # Start REST API on port 8080
```

### Evaluators
- `evaluators/file_content.py` - Repo structure analysis (18 signals)
- `evaluators/git_history.py` - Commit pattern analysis

### Key Files
- `scorecards/` - Product scorecards (audit, pillar, enriched)
- `rubric/rubric-v1.json` - 3,598 criteria across 30 domains
- `output/dashboard.html` - Generated dashboard
- `history/scores.jsonl` - Regression tracker

### Portfolio Context
- **146 repos** → **78 actionable** (63 managed + 15 incubators)
- **Target:** 45-70 canonical active repos, 10-20 public product brands
- **Protocol:** mandate → mission → assignment → epoch → implementation → findings → decision

### Quality Gates
- Unit/Integration/E2E coverage: >=85%
- Critical obligations: 100%
- G0-G6 completeness model

### Behavioral Constraints
- Research before implement
- Fix forward, never revert
- No repo deletion to improve count
- No README accepted as proof alone
- No quality suite trusted until negative controls show it can fail
