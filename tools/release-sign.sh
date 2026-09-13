#!/usr/bin/env bash
# tools/release-sign.sh -- libpdx-net.M5-001 (libpdx-net#21)
#
# Dual-signed release-manifest emitter for the v1.0 signed
# release. STUB at v0.2.0 -- real body pending.
#
# =============================================================================
# SCOPE (design/networking/r100-user-tools-plan.md §13.1 M5-001)
# =============================================================================
#
# M5-001 gates the v1.0 signed release on three artifacts landing
# together under one `git tag`:
#
#   1. manifest.pdxsig  -- dual-signed release manifest binding
#                          (workspace.version, git tag,
#                          CHANGELOG.md sha256, per-source-file
#                          sha256 table, deps.list sha256,
#                          caps.decl sha256). Dual signatures:
#                          Ed25519 (release-key) + ML-DSA-65
#                          (long-term archival key). ML-DSA-65
#                          half is what makes the signature
#                          post-quantum-durable per plan §12.4.
#   2. CHANGELOG-1.0    -- the frozen v1.0 CHANGELOG entry
#                          extracted from CHANGELOG.md; signed
#                          separately so a downstream mirror
#                          consumer can verify the CHANGELOG
#                          without pulling the whole tree.
#   3. libpdx-net.pdxdoc -- the compiled .pdxdoc bundle for the
#                          public API surface (net_api.pdx +
#                          every schema in caps.decl). Bundle
#                          format tracked by paideia-os
#                          libpdx-docgen (issue TBD).
#
# =============================================================================
# BLOCKED ON
# =============================================================================
#
#   * paideia-as `mldsa65_sign` intrinsic (paideia-as follow-up
#     per plan §12.4). No stable ABI yet; a caller cannot even
#     stub the second-signature call site.
#   * pdxsig canonical wire format (draft in
#     design/security/pdxsig-v1.md on paideia-os -- not yet
#     landed; issue TBD).
#   * libpdx-docgen .pdxdoc bundler (paideia-os issue TBD --
#     .pdxdoc format is not yet reference-implemented).
#   * KIND_RELEASE_SIGNING_KEY capability (paideia-os issue
#     TBD -- pdxtrust milestone).
#
# All four blockers are on the paideia-os side; libpdx-net cannot
# unblock any of them locally. This script exists as the swap
# site: when the four upstream items land, the body below
# replaces its `exit 2` refusal with the real dual-sign flow and
# every downstream release script that shells out to
# `tools/release-sign.sh` continues to work without a rename.
#
# =============================================================================
# INVOCATION CONTRACT (frozen for future body)
# =============================================================================
#
#   tools/release-sign.sh <release-tag> [--dry-run]
#
#   Environment inputs (all required for the real body):
#     PDX_ED25519_SIGNING_KEY   -- path to release-key private key
#     PDX_MLDSA65_SIGNING_KEY   -- path to ML-DSA-65 archival key
#     PDX_DOCGEN                -- path to libpdx-docgen binary
#     PDX_PDXSIG                -- path to pdxsig writer binary
#
#   Outputs (in build-out/):
#     manifest.pdxsig
#     CHANGELOG-1.0.pdxsig
#     libpdx-net.pdxdoc.pdxsig
#     libpdx-net-<tag>.tar.gz  (bundled release tarball)

set -euo pipefail
cd "$(dirname "$0")/.."

echo "[release-sign] libpdx-net M5-001 dual-signed release" >&2
echo "[release-sign] STUB at v0.2.0 -- body pending upstream items:" >&2
echo "[release-sign]   * paideia-as mldsa65_sign intrinsic (blocked)" >&2
echo "[release-sign]   * pdxsig canonical wire format (blocked)" >&2
echo "[release-sign]   * libpdx-docgen .pdxdoc bundler (blocked)" >&2
echo "[release-sign]   * KIND_RELEASE_SIGNING_KEY capability (blocked)" >&2
echo "[release-sign] See libpdx-net#21 for landing plan." >&2
exit 2
