# Source reconciliation next gates

Scope: unresolved source identity, immutable revision/hash, and conversion issues
recorded in the four dry-run reports. No facts are inferred; candidates remain
UNREVIEWED and publication/readiness remains blocked.

## Substrate

| Issue | Current label/evidence | Concrete gate |
|---|---|---|
| User-mentioned Substrate Genesis identity is not established; local README describes a dispatch gateway, while the card names different components. | UNKNOWN | Obtain an authoritative source location/identity and an identity-bearing README or manifest; review and record equivalence before approval. |
| Archived card declares `main @ fe7dc66`, but the audited snapshot has no Git metadata to verify that revision. | UNKNOWN / BLOCKED | Provide a Git worktree or immutable source export proving the declared commit, with remote/branch metadata and reproducible revision evidence. |
| Separate local provenance records HEAD `393edad84a5d09dfb897d3bdfb43468816a27987`, differing from the card; this is not reverified in the live snapshot. | HISTORICAL / UNKNOWN | Recheck the exact source path and capture immutable HEAD plus the card revision; document the relationship or leave the candidate unapproved. |
| Preserved card hash (`ad4662...27148`) verifies file bytes only, not source identity or assessed revision. | VERIFIED hash; identity UNKNOWN | Bind the card hash to a verified source revision/export and record the complete source-to-card provenance. |
| Native-to-current-unified mapping has positional/set differences, duplicate IDs (including conflicting D-0006/D-0009), and distinct scales. | UNKNOWN / BLOCKED | Approve a reviewed, versioned mapping and duplicate-ID adjudication, then reproduce conversion from immutable inputs with recorded generator/version. |

## Tracera

| Issue | Current label/evidence | Concrete gate |
|---|---|---|
| Recorded exact path is absent; preserved candidate is under `Tracera-wtrees` instead. | VERIFIED absence; source identity UNKNOWN | Locate or explicitly designate the assessed source path and obtain an authoritative identity binding; do not silently substitute the candidate. |
| Preserved candidate has a file hash (`256d0391...762de`) but no Git metadata; exact assessed commit and clean state cannot be verified. | VERIFIED hash; BLOCKED | Supply immutable commit/export evidence (remote, HEAD, branch, and worktree state) matching the preserved card hash. |
| README identity is unavailable at both audited roots. | UNKNOWN | Provide an identity-bearing README/manifest or other authoritative repository metadata and review it. |
| Native 435/435 weighting is underdocumented: no included IDs, cluster weights, or executable selection rule; 96 pillars total 480. | UNKNOWN / BLOCKED | Publish and review the exact 435 selection and weight vector, then run a deterministic conversion producing the unified rows. |
| No immutable converter revision/version ties native L# pillars to the 47 unified IDs; recorded `(latest)` is not immutable. | UNKNOWN | Record converter/generator version and immutable source revision, plus a reviewed per-ID mapping and reproducible hash-addressed output. |

## Release gate

No source candidate may be approved until the applicable identity, immutable
revision/hash binding, and reviewed conversion-rule gates above pass. Existing
artifact hashes establish preservation only; they do not close identity or
lineage gaps.
