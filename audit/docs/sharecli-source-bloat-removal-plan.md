# sharecli Source Bloat Removal Plan

**Date:** 2026-09-13
**Issue:** Source bloat with ~10,000+ lines of unrelated modules
**Priority:** MEDIUM (third priority after HexaKit and argis-extensions)

---

## Problem Statement

The `src/` directory contains modules with **no apparent connection** to a "CLI process manager for agent orchestration". These modules:
- Inflate line counts and test counts
- Dilute the signal-to-noise ratio
- Make coverage appear lower than it should be
- Add zero functional value to the product

---

## Identified Bloat Modules

| Module | Lines | Actual Domain | Relevance to Product |
|--------|-------|---------------|---------------------|
| `erf.rs` | ~500 | Error function math | NONE |
| `dhcp_options.rs` | ~500 | DHCP protocol parsing | NONE |
| `snmpv3_msg.rs` | ~500 | SNMP v3 message parsing | NONE |
| `bitcoin_bech32.rs` | ~451 | Bitcoin address encoding | NONE |
| `asn1_ber.rs` | ~459 | ASN.1/BER encoding | NONE |
| `ldap_filter.rs` | ~417 | LDAP filter parsing | NONE |
| `wasm_opcode.rs` | ~656 | WebAssembly opcodes | NONE |
| `x12_edi_segment.rs` | ~496 | X12 EDI parsing | NONE |
| `dns_query_parser.rs` | ~603 | DNS query parsing | NONE |
| `dns_zone.rs` | ~512 | DNS zone file parsing | NONE |
| `oauth1_signature.rs` | ~590 | OAuth1 signature computation | NONE |
| `imap_response.rs` | ~583 | IMAP response parsing | NONE |
| `qoi_image.rs` | ~500 | QOI image format | NONE |
| `bmp_image.rs` | ~422 | BMP image format | NONE |
| `tar_header.rs` | ~500 | Tar header parsing | NONE |
| `git_pack_idx.rs` | ~500 | Git pack index | NONE |
| `lz4_block.rs` | ~500 | LZ4 compression | NONE |
| `json5.rs` | ~500 | JSON5 parser | NONE |
| `blake2.rs` | ~452 | Blake2 hash | NONE |
| `roman_numeral.rs` | ~500 | Roman numeral conversion | NONE |
| `base_n_radix.rs` | ~500 | Base-N radix conversion | NONE |
| `money.rs` | ~500 | Money/financial type | NONE |
| `bellman_ford.rs` | ~500 | Graph algorithm | NONE |
| `vector_3d.rs` | ~500 | 3D vector math | NONE |

**Total estimated padding:** ~12,000+ lines of code

---

## Fix Plan

### Phase 1: Audit and Classify (2-3 hours)
1. Review each module for actual usage in the codebase
2. Classify modules into:
   - **KEEP:** Core functionality (config, runtime, commands, process management)
   - **REMOVE:** Unrelated modules (listed above)
   - **EXTRACT:** Useful but unrelated modules (move to separate crate)
3. Create a detailed removal plan

### Phase 2: Remove Unrelated Modules (3-4 hours)
1. Remove each bloat module from `src/`
2. Remove associated tests
3. Remove any imports/references
4. Update `mod.rs` files
5. Verify compilation after each removal

### Phase 3: Verify and Test (2-3 hours)
1. Run full build: `cargo build --release`
2. Run full test suite: `cargo test`
3. Verify coverage increases (should hit 85% target)
4. Verify CI passes

### Phase 4: Clean Up Governance (1-2 hours)
1. Remove excessive CI workflows (61 -> ~10)
2. Simplify AGENTS.md for human contributors
3. Consolidate governance docs

---

## Estimated Total Time: 8-12 hours

---

## Risk Assessment

**Risk Level:** LOW
- Removing unrelated modules is safe
- No functional impact on product
- Only affects code metrics and coverage

**Mitigation:**
- Verify each module is truly unrelated before removal
- Test compilation after each removal
- Keep backups of removed modules

---

## Success Criteria

1. All bloat modules removed from `src/`
2. `cargo build --release` succeeds
3. `cargo test` passes
4. Coverage >= 85%
5. CI passes
6. Governance simplified

---

## Expected Impact

- **Line count reduction:** ~12,000+ lines removed
- **Test coverage increase:** Should hit 85% target
- **CI complexity reduction:** 61 -> ~10 workflows
- **Code clarity:** Product purpose becomes clear
- **Maintenance burden:** Significantly reduced

---

## Notes

- This is the highest-leverage fix for sharecli
- Removing source bloat will likely close the coverage gap automatically
- Consider creating a separate "algorithms" crate if any modules are useful
- Focus on core functionality: process management, agent runtime, resource monitoring
