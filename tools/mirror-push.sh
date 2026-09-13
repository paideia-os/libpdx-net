#!/usr/bin/env bash
# tools/mirror-push.sh -- libpdx-net.M5-002 (libpdx-net#22)
#
# Multi-mirror release push for the v1.0 signed release tarball.
# STUB at v0.2.0 -- real body pending M5-001 (#21) landing.
#
# =============================================================================
# SCOPE (design/networking/r100-user-tools-plan.md §13.1 M5-002)
# =============================================================================
#
# M5-002 gates the "pull libpdx-net from any of N geographically-
# distributed mirrors, verify the signature, install" story that
# lets a paideia-os user tool bootstrap network access without
# trusting a single hosting provider. Concretely: after M5-001
# (#21) has produced `build-out/libpdx-net-<tag>.tar.gz` plus
# `manifest.pdxsig`, this script pushes the two artifacts to
# every mirror declared in `MIRRORS.list` and verifies each
# push landed by re-downloading and re-verifying the signature.
#
# =============================================================================
# BLOCKED ON
# =============================================================================
#
#   * M5-001 (libpdx-net#21) MUST land first -- this script has
#     no artifacts to push until the dual-signed release tarball
#     exists. See tools/release-sign.sh for that side's blockers.
#   * MIRRORS.list format (not yet designed -- issue TBD on
#     paideia-os `design/security/release-mirrors.md`). Provisional
#     shape: one URL per line, `# comment`s and blank lines
#     ignored; every URL is a directory that accepts a signed
#     PUT via a mirror-adminstrator-provided credential.
#   * Mirror-side upload protocol -- provisional choice is
#     signed rsync over ssh; final choice tracked by the mirror
#     spec above. libpdx-net does not itself run the mirror
#     side; this script is the CLIENT.
#   * Verification loop uses a future `pdxsig-verify` binary
#     (paideia-os issue TBD, sibling of pdxsig itself).
#
# All four blockers are upstream. This script exists as the swap
# site: when the mirror spec + pdxsig-verify + a working M5-001
# tarball all land, the body below flips its `exit 2` refusal for
# the real push+verify loop; downstream release automation that
# shells out to `tools/mirror-push.sh` continues to work without
# a rename.
#
# =============================================================================
# INVOCATION CONTRACT (frozen for future body)
# =============================================================================
#
#   tools/mirror-push.sh <release-tag> [--mirrors MIRRORS.list] [--dry-run]
#
#   Environment inputs (all required for the real body):
#     PDX_MIRROR_CREDENTIALS_DIR  -- per-mirror push credentials
#     PDX_PDXSIG_VERIFY           -- path to pdxsig-verify binary
#
#   Inputs (from M5-001 output):
#     build-out/libpdx-net-<tag>.tar.gz
#     build-out/manifest.pdxsig
#     build-out/CHANGELOG-1.0.pdxsig
#     build-out/libpdx-net.pdxdoc.pdxsig
#
#   Exit codes:
#     0   -- every mirror uploaded and re-verified
#     1   -- one or more mirrors failed upload
#     2   -- pre-conditions unmet (M5-001 output missing, no
#            MIRRORS.list, ...)

set -euo pipefail
cd "$(dirname "$0")/.."

echo "[mirror-push] libpdx-net M5-002 multi-mirror release push" >&2
echo "[mirror-push] STUB at v0.2.0 -- body pending upstream items:" >&2
echo "[mirror-push]   * M5-001 (#21) dual-signed release tarball (blocked)" >&2
echo "[mirror-push]   * MIRRORS.list format spec (blocked)" >&2
echo "[mirror-push]   * pdxsig-verify binary (blocked)" >&2
echo "[mirror-push]   * mirror upload protocol (blocked)" >&2
echo "[mirror-push] See libpdx-net#22 for landing plan." >&2
exit 2
