# libpdx-net -- status

**Wave:** R100 (client-side networking SDK)
**Current milestone:** Wave X drain (v0.2.0) -- M1-001 (#1)
  scaffold witness, M1-002 (#2) public API stubs, M1-003 (#3)
  enum-invariant first-runnable test, M5-001 (#21) + M5-002
  (#22) release-tool swap-site placeholders. Wave N (v0.1.0)
  M3-005/006 + M4-001/002/003 remain landed. Real socket
  bodies + TLS handshake bodies remain pending upstream PREP
  items.
**Version:** 0.2.0 (2026-09-13)

See `design/networking/r100-user-tools-plan.md` in paideia-os for the
full R100 API surface + milestone catalog.

## What ships at v0.2.0

- `src/tool_ident.pdx` -- `PDX_TOOL_NAME` + `PDX_TOOL_VERSION` externs
  (v0.2.0).
- `src/net_types.pdx` -- four error bands (NetErr / DnsErr / TlsErr /
  HttpErr).
- `src/net_api.pdx` -- **#2** M1-002 nine public API stubs
  (net_socket/bind/connect/send/recv/close/inet_pton/resolve/tls_wrap).
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
- `tests/net_types_selftest.pdx` -- **#3** M1-003 first-runnable
  stub test (enum band-invariant check).
- `tools/release-sign.sh` -- **#21** M5-001 dual-signed release
  swap-site placeholder (exit 2 pending upstream).
- `tools/mirror-push.sh` -- **#22** M5-002 mirror push + verify
  swap-site placeholder (exit 2 pending upstream).
- `caps.decl`, `deps.list`, `manifest.pdxproj`, `.gitignore`,
  `tools/build.sh`, `CHANGELOG.md`.

## What is deferred

- **Real socket bodies** for M2 (issues #4-#10). Scoped to a
  separate landing.
- **TLS handshake + record layer** for M3-001..M3-004 (issues
  #11-#14). Blocked on paideia-as crypto intrinsics (§12.4).
- **Redirect handling** for M4-004 (issue #20). Separate landing.
- **Real M5-001 dual-sign body** (issue #21) -- placeholder ships
  at v0.2.0; body pending paideia-as `mldsa65_sign` + pdxsig
  wire format + libpdx-docgen + KIND_RELEASE_SIGNING_KEY.
- **Real M5-002 push+verify body** (issue #22) -- placeholder
  ships at v0.2.0; body pending M5-001 + MIRRORS.list spec +
  pdxsig-verify + mirror upload protocol.

## Build discipline

`bash tools/build.sh` runs `paideia-as build --emit elf64` over every
`src/*.pdx`; per-file object emit only (no cross-file link resolution
at this step -- undefined externals across files are a link-time
concern). Toolchain floor: paideia-as >= 0.21.0.

**v0.2.0 landing NOT built by this drain pass.** Main should invoke
`bash tools/build.sh` and re-invoke softarch with the error tail if it
fails (per project standing rule: builds are main-only, sub-agents
never invoke build.sh).

## Wire contracts

- `TlsHandshakeRecord@0.1` (net_tls_record.pdx) -- 128 bytes,
  emitted via `sys_semantic_send` on every handshake outcome.
- `PDX_TOOL_NAME` / `PDX_TOOL_VERSION` (tool_ident.pdx) -- libpdx-argv
  1.1.3 Wave 6 extern contract.
