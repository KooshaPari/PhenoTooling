# Desktop Source Discovery

Status: BLOCKED (desktop discovery could not be performed).

## Connectivity

- **UNKNOWN/UNAVAILABLE:** approved read-only alias `desktop-kooshapari-desk`.
- Command: `ssh -o BatchMode=yes -o ConnectTimeout=8 desktop-kooshapari-desk 'printf DESKTOP_OK'`
- Result: `ssh: Could not resolve hostname desktop-kooshapari-desk: nodename nor servname provided, or not known`
- No remote filesystem, Git metadata, README, manifest, HEAD, remote, or source-card
  paths were inspected.

## Local candidate paths observed

Read-only local directory discovery found these candidate directories:

- `/Users/kooshapari/CodeProjects/Phenotype/repos/pheno/Tracera`
- `/Users/kooshapari/CodeProjects/Phenotype/repos/substrate`
- `/Users/kooshapari/CodeProjects/Phenotype/repos/Tracera-wtrees`
- `/Users/kooshapari/CodeProjects/Phenotype/repos/Tracera`

These are only directory-name matches, not authoritative identity or source-card
determinations. Their Git HEADs/remotes and README/manifest contents remain **UNKNOWN**.

## Required discovery results

- Authoritative Substrate repository identity: **UNKNOWN**.
- Authoritative Tracera repository identity: **UNKNOWN**.
- README/manifest authority: **UNKNOWN**.
- Git HEAD and remote authority: **UNKNOWN**.
- Exact authoritative source-card paths: **UNKNOWN**.
- Desktop/source verification: **BLOCKED** until the approved SSH alias resolves and connects.

No remote writes, service operations, builds, tests, or destructive commands were run.
