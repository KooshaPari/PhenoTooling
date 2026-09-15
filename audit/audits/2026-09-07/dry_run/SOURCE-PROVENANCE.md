# Source provenance investigation

Read-only evidence checks on 2026-09-08/09; additive reports and a local static discovery payload written.
Paths below are relative to `research/audit-system/` unless explicitly absolute.
All source candidates remain UNREVIEWED; publication remains blocked.

| Subject | Verified evidence | Remaining gap |
|---|---|---|
| Summary `substrate` | `scorecards/SUMMARY.json`: 253 scored rubric rows, 95.26%, grade A; no source_card | Source/conversion lineage missing, not evidence of repository absence |
| Preserved Substrate card | `repos/substrate/audit_scorecard.json`: kooshapari/substrate, 2026-07-22, main @ fe7dc66; 140 pillars, 126 satisfied, 14 partial, 95.0% native | Candidate conversion differs from unified rows |
| Local Substrate repository | `repos/substrate`; origin https://github.com/KooshaPari/substrate.git; HEAD 393edad84a5d09dfb897d3bdfb43468816a27987 | Current HEAD is not the card's assessed commit |
| Substrate meaning | Local README calls it a hexagonal AI dispatch gateway and TUI; card cites substrate-core, substrate-app, psub-gateway and driver-http | No verified equivalence to user-mentioned Substrate Genesis |
| Tracera recorded path | `repos/Tracera/fix-contract-tests-20260901/audit/SCORECARD-FULL-2026-08-30.md` remains missing | Do not silently substitute another path |
| Tracera preserved candidate | `repos/Tracera-wtrees/fix-contract-tests-20260901/audit/SCORECARD-FULL-2026-08-30.md` exists; declares tracera, 2026-08-30, commit HEAD | Exact assessed commit and reviewed conversion unknown |
| Desk Genesis discovery | Existing private SSH route authenticated; bounded discovery completed | Genesis source location/identity remains UNKNOWN, not absent |

## Conversion checks

Substrate's 140 native rows map to 140 rows using `rubric/id-crosswalk.json`.
Neither ordered nor sorted mapped `(id,status)` rows equal `scorecards/substrate-audit.json`.
Set comparison has 22 distinct `(id,status)` values unique to each side; this is not a count of adjudicated criteria.
Unified Substrate has 140 input rows, 127 unique IDs, 13 duplicate-ID groups.
Conflicting groups are D-0006 and D-0009. Their rubric IDs cross documentation, dx and DeepEval subjects.
The legacy scorer overwrites duplicate audit IDs and then matches all rubric rows by bare ID.
Native 95.0% and unified 95.26% therefore remain distinct scales; no readiness inference or source approval follows.

Tracera's candidate uses L#1-L#96, 0-5 scores and claims 435/435.
Its eleven cluster maxima sum to 480; Appendix D lines 1788-1848 explicitly says 435 is a weighted/prioritized subset, without identifying its members or cluster weights.
The unified input instead contains 47 criteria and scores 116 rubric rows.
No reviewed transformation tying those native pillars to the unified IDs was found in the inspected artifacts.
Matching candidate subject/date/hash resolves file discovery only, not full conversion lineage.

## Verified SHA-256 values

| Artifact | SHA-256 |
|---|---|
| repos/substrate/audit_scorecard.json | ad4662b6b6a441588bbf606b439d45083f8b32e033c6b81ae6e573388ed27148 |
| scorecards/substrate-audit.json | 669d605954524c410ad4b4b946881df0258cdf9a4ef7d1118f5dcfd9c0bfb0ce |
| Tracera preserved candidate above | 256d03913ef633b6f11340487353a6f2dbf620f7f059f0f2e4600519d7c762de |
| scorecards/Tracera-wtrees-audit.json | 08e4debd13d55254d0715e9301caab3f4830b463820b88dcf16572a47f75aba1 |
| rubric/id-crosswalk.json | 18267481af022e57b1148b092daf6a48753c4783bff7f7dc7f8cc308a537df9f |
| rubric/scoring.py | faeb333db3e3db4aed2a6cecc6f5860dec4307b54ff881a40387e07493125034 |
| rubric/rubric-v1.json | e50b5c2875ef2ef00cf4b69e43f818373922852ac050914086aa1cc822f1dad6 |

Both preserved native-card hashes match `audits/2026-09-07/snapshot-evidence.json`.

## Desk scope and outcome
Configured alias kooshapari-desk resolves to user koosh, private Tailscale 100.96.135.160:22, existing identity id-git and known host key.
Tailscale reported that peer online. StrictHostKeyChecking=yes and BatchMode=yes were used; no SSH configuration was changed.
Attempt 1 authenticated but PowerShell quoting caused `Missing variable name after foreach`; no discovery result.
The coordinator authorized one corrected attempt using EncodedCommand; attempt 2 exited 0.
Search started at the user profile and C:/, D:/, E:/, followed selected project-directory names only, depth at most four and first 100 children per directory.
Observed roots included C:/Users/koosh, C:/dev, D:/codeprojects, D:/Dev, D:/koosh and C:/Users/kooshapari.
Only matching name was D:/cargo-target-substrate282-memory-test-20260809c; none of the four queried source-card/manifest filenames was returned there.
Final coordinator-authorized check used local `desk-discovery-static.ps1`: UTF-16LE/base64 round-trip cmp and local PowerShell parser both passed; SHA256 57f003125a54b40d047682efe6ebfaf35e27f13bc88719566201a7c1f05034f0.
The private-IP SSH session used BatchMode/StrictHostKeyChecking, existing id-git, 8s connect and 30s total timeout; exited 0 with DISCOVERY_COMPLETE. Payload contains no PowerShell variables, preventing the earlier interpolation error.
It listed 33 immediate directories across six explicit roots, including D:/codeprojects/incoming, D:/Dev/Dino-worktrees, D:/koosh/pheno-control-plane, pheno-research, pheno-harness, PhenoCompose, PhenoPlugins and phenotype-omlx; no Genesis/Substrate name appeared.
WSL listing reported FedoraLinux-44 Running (v2), podman-machine-default Stopped (v2), docker-desktop Stopped (v2). No distribution was launched or queried internally.
Focused follow-up `desk-identity-static.ps1` passed local encoding round-trip/parser checks (SHA256 dd773b996361dae576eee52a825c3929f811f4227ff59c3f5d600c034f12c3fc), then SSH exited 0 with IDENTITY_CHECK_COMPLETE. D:/koosh/pheno-control-plane has origin https://github.com/KooshaPari/pheno-control-plane.git and HEAD 1ec8a3bdf8e12527277a49ef88d875789b7889ed; README describes a Windows Tailnet R&D hub using NATS JetStream/MinIO, not an established Genesis identity.
The exact-running-distro guard returned FEDORA_NOT_RUNNING_SKIPPED, so no Linux directory query ran; that marker proves no confirmed running match, not independently that Fedora stopped. Genesis location remains UNKNOWN. No additional discovery followed; absent identity is not an established user blocker.
