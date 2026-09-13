# libpdx-net -- status

**Wave:** R100 (client-side networking SDK)
**Current milestone:** Wave N scaffold seed (v0.1.0) --
  M3-005 (#15), M3-006 (#16), M4-001 (#17), M4-002 (#18),
  M4-003 (#19) landed as per-file source scaffolds; sockets +
  TLS handshake bodies pending upstream PREP items.
**Version:** 0.1.0 (2026-09-13)

See `design/networking/r100-user-tools-plan.md` in paideia-os for the
full R100 API surface + milestone catalog.

## What ships at v0.1.0

- `src/tool_ident.pdx` -- `PDX_TOOL_NAME` + `PDX_TOOL_VERSION` externs.
- `src/net_types.pdx` -- four error bands (NetErr / DnsErr / TlsErr /
  HttpErr).
- `src/net_tls_record.pdx` -- **#15** M3-005 TlsHandshakeRecord@0.1
  schema + fail-closed emit stub.
- `src/net_dns_txid.pdx` -- **#16** M3-006 WEAK_ENTROPY_FALLBACK TXID
  generator + verify + header-ID write.
- `src/net_http_request.pdx` -- **#17/#18** M4-001 GET + M4-002 POST
  encode stubs + body-slot threader.
- `src/net_http_response.pdx` -- **#17** M4-001 response-struct
  init + parse stub.
- `src/net_http_chunked.pdx` -- **#19** M4-003 chunked-decoder stub +
  landed ASCII-hex-digit helper.
- `caps.decl`, `deps.list`, `manifest.pdxproj`, `.gitignore`,
  `tools/build.sh`, `CHANGELOG.md`.

## What is deferred

- **Real socket bodies** for M2 (issues #4-#10). Scoped to a
  separate landing.
- **TLS handshake + record layer** for M3-001..M3-004 (issues
  #11-#14). Blocked on paideia-as crypto intrinsics (§12.4).
- **Redirect handling** for M4-004 (issue #20). Separate landing.
- **Signed release** at M5-001/002 (issues #21/#22).

## Build discipline

`bash tools/build.sh` runs `paideia-as build --emit elf64` over every
`src/*.pdx`; per-file object emit only (no cross-file link resolution
at this step -- undefined externals across files are a link-time
concern). Toolchain floor: paideia-as >= 0.21.0.

**v0.1.0 landing NOT built by this seeding pass.** Main should invoke
`bash tools/build.sh` and re-invoke softarch with the error tail if it
fails (per project standing rule: builds are main-only, sub-agents
never invoke build.sh).

## Wire contracts

- `TlsHandshakeRecord@0.1` (net_tls_record.pdx) -- 128 bytes,
  emitted via `sys_semantic_send` on every handshake outcome.
- `PDX_TOOL_NAME` / `PDX_TOOL_VERSION` (tool_ident.pdx) -- libpdx-argv
  1.1.3 Wave 6 extern contract.
