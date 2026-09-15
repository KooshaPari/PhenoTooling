# Dry-run path registry

Recorded paths only; paths and status labels are taken from the existing
dry-run reports. `Exists` is a local filesystem check where an actual local
path is known. No recorded missing path is substituted.

| Category | Recorded path | Actual local path if known | Exists | Role | Status |
|---|---|---|---|---|---|
| Rubric | `rubric/` | `/Users/kooshapari/CodeProjects/Phenotype/repos/research/audit-system/rubric/` | yes | Rubric inputs/scorer | VERIFIED |
| Scorecards | `scorecards/` | `/Users/kooshapari/CodeProjects/Phenotype/repos/research/audit-system/scorecards/` | yes | Generated scorecard outputs | UNKNOWN |
| Tracera recorded path | `repos/Tracera/fix-contract-tests-20260901/audit/SCORECARD-FULL-2026-08-30.md` | `/Users/kooshapari/CodeProjects/Phenotype/repos/research/audit-system/repos/Tracera/fix-contract-tests-20260901/audit/SCORECARD-FULL-2026-08-30.md` | no | Exact recorded Tracera source card | VERIFIED |
| Tracera-wtrees candidate | `repos/Tracera-wtrees/fix-contract-tests-20260901/audit/SCORECARD-FULL-2026-08-30.md` | `/Users/kooshapari/CodeProjects/Phenotype/repos/research/audit-system/repos/Tracera-wtrees/fix-contract-tests-20260901/audit/SCORECARD-FULL-2026-08-30.md` | yes | Preserved Tracera source-card candidate | UNKNOWN |
| Substrate card | `repos/substrate/audit_scorecard.json` | `/Users/kooshapari/CodeProjects/Phenotype/repos/research/audit-system/repos/substrate/audit_scorecard.json` | yes | Preserved native Substrate card | UNKNOWN |
| Desktop alias | `desktop-kooshapari-desk` | unknown | no | Approved read-only desktop route | BLOCKED |
| Desktop alias | `kooshapari-desk` | unknown | no | Configured desktop route | UNKNOWN |
| Desktop candidate | `/Users/kooshapari/CodeProjects/Phenotype/repos/pheno/Tracera` | `/Users/kooshapari/CodeProjects/Phenotype/repos/pheno/Tracera` | yes | Local directory-name candidate | UNKNOWN |
| Desktop candidate | `/Users/kooshapari/CodeProjects/Phenotype/repos/substrate` | `/Users/kooshapari/CodeProjects/Phenotype/repos/substrate` | yes | Local directory-name candidate | VERIFIED |
| Desktop candidate | `/Users/kooshapari/CodeProjects/Phenotype/repos/Tracera-wtrees` | `/Users/kooshapari/CodeProjects/Phenotype/repos/Tracera-wtrees` | yes | Local directory-name candidate | UNKNOWN |
| Desktop candidate | `/Users/kooshapari/CodeProjects/Phenotype/repos/Tracera` | `/Users/kooshapari/CodeProjects/Phenotype/repos/Tracera` | yes | Local directory-name candidate | UNKNOWN |
| Desktop observed root | `C:/Users/koosh` | unknown | no | Bounded desktop discovery root | UNKNOWN |
| Desktop observed root | `C:/dev` | unknown | no | Bounded desktop discovery root | UNKNOWN |
| Desktop observed root | `D:/codeprojects` | unknown | no | Bounded desktop discovery root | UNKNOWN |
| Desktop observed root | `D:/Dev` | unknown | no | Bounded desktop discovery root | UNKNOWN |
| Desktop observed root | `D:/koosh` | unknown | no | Bounded desktop discovery root | UNKNOWN |
| Desktop observed root | `C:/Users/kooshapari` | unknown | no | Bounded desktop discovery root | UNKNOWN |
| Desktop discovered candidate | `D:/cargo-target-substrate282-memory-test-20260809c` | unknown | no | Only matching remote directory name | UNKNOWN |

The Tracera recorded path remains missing; the Tracera-wtrees row is retained as
a candidate and is not treated as a replacement. Desktop discovery remains
blocked or unknown as recorded.
