# libpdx-net -- status

**Wave:** R100 (client-side networking SDK)
**Current milestone:** Wave NN (v0.4.0) -- M2-002 (#5) real
  bind/listen/accept, M2-007 (#10) UDP resolver transport,
  M4-004 (#20) redirect handling, M3-001 (#11) TLS ClientHello
  scaffold, M3-002 (#12) TLS key schedule scaffold. Wave MM
  (v0.3.0) M2-001/003/004/005/006 remain landed. TLS handshake
  bodies remain pending R100-PREP-005 (paideia-as crypto FFI
  thunks -- confirmed still not linkable as of this wave, see
  net_tls_key_schedule.pdx).
**Version:** 0.4.0 (2026-09-13)

See `design/networking/r100-user-tools-plan.md` in paideia-os for the
full R100 API surface + milestone catalog.

## What ships at v0.4.0 (this wave, NEW)

- `src/net_server.pdx` -- **#5** M2-002 real `net_server_bind`/
  `net_server_listen`/`net_server_accept` trampolines (SC+ 88/89/90).
  `net_api.pdx`'s `net_bind` swaps to an adapter over
  `net_server_bind`; `net_listen`/`net_accept` are brand-new additive
  public entries (not part of the original nine-symbol M1-002
  contract).
- `src/net_resolve_udp.pdx` -- **#10** M2-007 real UDP transport for
  the resolver: wires net_dns_query.pdx + net_dns_parse.pdx +
  net_dns_txid.pdx over net_tcp.pdx's trampolines (transport-agnostic
  -- a UDP fd rides the same syscalls a TCP fd does). WEAK
  floor-only 3-second `sys_setsockopt` timeout attempt (confirmed
  no-op against the live kernel -- no SO_RCVTIMEO exists yet) +
  WEAK placeholder resolver address (127.0.0.1:53, pending §9.4's
  boot-seeded `/boot/resolv.default` read).
- `src/net_http_redirect.pdx` -- **#20** M4-004 redirect
  method-preservation matrix (301/302/303 downgrade POST->GET,
  307/308 preserve), 10-hop cap, cross-scheme-downgrade refusal.
- `src/net_tls_wrap.pdx` -- **#11** M3-001 TLS 1.3 ClientHello,
  scaffold-only: fixed 158-byte template (32-byte SNI slot),
  WEAK-zero random + key_share, emits via `net_tcp_send` without
  waiting for a ServerHello. R100-PREP-005 blocked for the real
  handshake.
- `src/net_tls_key_schedule.pdx` -- **#12** M3-002 TLS 1.3 key
  schedule, WEAK stub: confirmed `paideia_crypto_hkdf_sha256` is NOT
  a linkable extern-C symbol as of this wave (HKDF/HMAC-SHA256/
  SHA-256 landed internally in paideia-as-crypto but with no FFI
  thunk -- #1339/#1338, vs. the Argon2id/ChaCha20-Poly1305/ML-KEM-768
  thunks #1348 DOES expose); zero-fills the 96-byte secret output.

## What shipped at v0.3.0 (Wave MM)

- `src/net_tcp.pdx` -- **#4** M2-001 real socket/connect/send/recv/
  close trampolines (SC+ 87/91/92/93/3); `net_api.pdx`'s five
  matching stubs swapped to delegate to them.
- `src/net_endian.pdx` -- **#6** M2-003 htons/ntohs/htonl/ntohl.
- `src/net_inet.pdx` -- **#7** M2-004 real dotted-quad IPv4 parse
  engine (`net_inet_pton_raw`); `net_api.pdx`'s `net_inet_pton`
  swapped to a thin adapter over it.
- `src/net_dns_query.pdx` -- **#8** M2-005 DNS query builder.
- `src/net_dns_parse.pdx` -- **#9** M2-006 DNS response parser
  (header/rcode/ancount + A/CNAME decode, name decompression).

## What shipped at v0.2.0 (Wave X drain)

- `src/tool_ident.pdx` -- `PDX_TOOL_NAME` + `PDX_TOOL_VERSION` externs.
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

- **Real M3 TLS handshake** (M3-003 cert verify #13, M3-004 record
  layer #14). Blocked on R100-PREP-005 -- as of v0.4.0, confirmed
  the paideia-as crypto FFI thunk layer still exposes no HKDF/
  HMAC-SHA256/SHA-256/Ed25519 symbols (only Argon2id/
  ChaCha20-Poly1305/ML-KEM-768).
- **Real M3-001/M3-002 bodies** (this wave's #11/#12 ship
  scaffold-only per the same R100-PREP-005 gap -- see the v0.4.0
  section above).
- **Real M5-001 dual-sign body** (issue #21) -- placeholder ships;
  body pending paideia-as `mldsa65_sign` + pdxsig wire format +
  libpdx-docgen + KIND_RELEASE_SIGNING_KEY.
- **Real M5-002 push+verify body** (issue #22) -- placeholder
  ships; body pending M5-001 + MIRRORS.list spec + pdxsig-verify +
  mirror upload protocol.
- **Real §9.4 boot-seeded resolver config** -- net_resolve_udp.pdx
  uses a WEAK placeholder resolver address (127.0.0.1:53) pending
  `/boot/resolv.default`.

## Build discipline

`bash tools/build.sh` runs `paideia-as build --emit elf64` over every
`src/*.pdx`; per-file object emit only (no cross-file link resolution
at this step -- undefined externals across files are a link-time
concern). Toolchain floor: paideia-as >= 0.21.0.

**v0.4.0 landing NOT built by this drain pass.** Main should invoke
`bash tools/build.sh` and re-invoke softarch with the error tail if it
fails (per project standing rule: builds are main-only, sub-agents
never invoke build.sh).

## Wire contracts

- `TlsHandshakeRecord@0.1` (net_tls_record.pdx) -- 128 bytes,
  emitted via `sys_semantic_send` on every handshake outcome.
- `PDX_TOOL_NAME` / `PDX_TOOL_VERSION` (tool_ident.pdx) -- libpdx-argv
  1.1.3 Wave 6 extern contract.
