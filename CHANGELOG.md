# libpdx-net -- CHANGELOG

All notable changes to this repository are documented here. Versioning
follows SemVer with a v0.x series until the M5 signed release.

## [0.4.0] -- 2026-09-13 (Wave NN: M2/M3/M4 tail)

**Scope:** land the remaining five M2/M3/M4 issues -- server-side
socket ops, the UDP resolver transport, redirect handling, and a
TLS 1.3 ClientHello + key-schedule scaffold pair.

### Landed

- `#5` -- **M2-002 real bind/listen/accept.** `src/net_server.pdx`
  (module `NetServer`) publishes `net_server_bind`/
  `net_server_listen`/`net_server_accept` over SC+ 88/89/90.
  Live-code check found the kernel ABI has no sockaddr concept at
  all (`(fd, local_port)`/`(fd, backlog)`/`(fd)` respectively,
  confirmed against `sys_bind.pdx`/`sys_listen.pdx`/`sys_accept.pdx`
  and `pdxsock`'s own "sockaddr_ptr prose is aspirational" note) --
  same trust-the-live-code correction net_tcp.pdx made for M2-001.
  `net_api.pdx`'s `net_bind` swaps to an adapter (reads `local_port`
  from an 8-byte value at `sa_va`); `net_listen`/`net_accept` are
  brand-new additive public entries (the M1-002 contract never named
  either).

- `#10` -- **M2-007 UDP resolver transport.** `src/net_resolve_udp.pdx`
  (module `NetResolveUdp`) publishes `net_resolve_udp(host_ptr,
  host_len, qtype, out_addr_ptr) -> u64`, wiring
  `net_dns_build_query` -> `net_tcp_socket`/`net_tcp_connect`/
  `net_tcp_send`/`net_tcp_recv`/`net_tcp_close` -> `net_dns_parse_response`
  -> `net_dns_txid_verify` (the TXID gate is mandatory and runs BEFORE
  any parsed address is trusted, per §2.3.1). WEAK floor-only 3-second
  `sys_setsockopt` timeout attempt (confirmed no-op against the live
  kernel -- no SO_RCVTIMEO optname exists in `sys_setsockopt.pdx`
  yet) with a real fallback: a same-call zero-byte UDP recv (already
  non-blocking on an empty ring) is treated as `DNS_ERR_TIMEOUT`. WEAK
  placeholder resolver address (127.0.0.1:53) pending §9.4's
  boot-seeded `/boot/resolv.default` read.

- `#20` -- **M4-004 redirect handling.** `src/net_http_redirect.pdx`
  (module `NetHttpRedirect`) publishes
  `net_http_follow_redirect(status_code, orig_method, params_ptr,
  hop_count) -> u64`: 301/302/303 downgrade POST to GET, 307/308
  preserve the method verbatim, a 10-hop cap checked before any
  status dispatch, and a cross-scheme (https->http) downgrade refusal
  checked uniformly across all five redirect statuses. Packs
  `location_ptr`/`location_len`/`orig_is_https` behind `params_ptr`
  (the issue's literal 5-argument signature exceeds the paideia-as
  4-argument ceiling, and the scheme-downgrade requirement needs an
  `orig_is_https` slot the issue's own signature never named).

- `#11` -- **M3-001 TLS 1.3 ClientHello (scaffold).**
  `src/net_tls_wrap.pdx` (module `NetTlsWrap`) publishes
  `net_tls_wrap(sock_fd, trust_cap, hostname_ptr, hostname_len) ->
  u64`: composes a fixed 158-byte ClientHello (32-byte SNI slot,
  TLS_AES_128_GCM_SHA256, x25519 + ed25519 + TLS 1.3-only extensions)
  and emits it via `net_tcp_send`. WEAK-zero `random` and the
  `key_share` public key; does not wait for or parse a ServerHello.
  `trust_cap` is accepted (four-argument contract) but unread --
  R100-PREP-005 blocked for any real verification.

- `#12` -- **M3-002 TLS 1.3 key schedule (scaffold).**
  `src/net_tls_key_schedule.pdx` (module `NetTlsKeySchedule`)
  publishes `net_tls_key_derive(shared_secret_ptr, shared_secret_len,
  out_secrets_ptr) -> u64`. Live-code check of `paideia-as-crypto`
  confirms HKDF-Extract/Expand + HMAC-SHA256 (#1339, v0.26.0) and
  SHA-256 (#1338, v0.25.0) landed as INTERNAL Rust traits with no
  extern-C FFI thunk (`paideia-as-crypto::ffi` / #1348 exposes only
  Argon2id / ChaCha20-Poly1305 / ML-KEM-768) -- `paideia_crypto_hkdf_sha256`
  is not a linkable symbol. Ships the WEAK stub side: zero-fills the
  96-byte early/handshake/master secret output and returns
  `TLS_ERR_NOT_IMPL`; documents the exact paideia-as-side follow-up
  needed to unblock the real body.

## [0.3.0] -- 2026-09-13 (Wave MM: M2 pure-function cohort)

**Scope:** land five M2 issues -- the first real (non-stub) bodies
in this library. `net_socket`/`net_connect`/`net_send`/`net_recv`/
`net_close`/`net_inet_pton` on the public `net_api.pdx` surface
swap from `NOT_IMPL` stubs to real bodies, in place, at the same
stable symbols.

### Landed

- `#4` -- **M2-001 real TCP wrapper.** `src/net_tcp.pdx` (module
  `NetTcp`) publishes five raw syscall trampolines --
  `net_tcp_socket`/`net_tcp_connect`/`net_tcp_send`/`net_tcp_recv`/
  `net_tcp_close` over SC+ 87/91/92/93/3 -- each a bare `mov rax,
  <sysno>; syscall; ret` (every argument already sits in the
  registers both the curried-fn ABI and the syscall ABI agree on, so
  no shuffling is needed). Landed under `net_tcp_*` names rather
  than net_api.pdx's own `net_socket`/etc. to avoid a duplicate-
  symbol link failure (paideia-as has no per-module symbol
  namespacing); `net_api.pdx`'s five corresponding stubs are swapped,
  this same landing, to delegate to these trampolines, fulfilling
  that file's own documented in-place-swap contract.

- `#6` -- **M2-003 endian helpers.** `src/net_endian.pdx` (module
  `NetEndian`) publishes `net_htons`/`net_ntohs`/`net_htonl`/
  `net_ntohl`, all `(u64) -> u64` leaf functions. Manual shl/shr/
  and/or byte-swap (the same proven shape `src/kernel/core/net/
  ethernet.pdx`'s own `htons` already uses) rather than `bswap` --
  no production `.pdx` body anywhere in the tree exercises that
  mnemonic yet.

- `#7` -- **M2-004 net_inet_pton.** `src/net_inet.pdx` (module
  `NetInet`) publishes the real dotted-quad IPv4 parse engine,
  `net_inet_pton_raw(str_ptr, str_len, out_be_ptr) -> 0|1`
  (out-pointer-shaped per the issue's own contract; suffixed `_raw`
  to avoid colliding with net_api.pdx's differently-shaped, older
  `net_inet_pton` stub). `net_api.pdx`'s `net_inet_pton` becomes a
  thin adapter: stack-scratch buffer, call the `_raw` engine, fold
  the 4 result bytes back into that stub's original packed-return
  contract.

- `#8` -- **M2-005 DNS query builder.** `src/net_dns_query.pdx`
  (module `NetDnsQuery`) publishes `net_dns_build_query(name_ptr,
  name_len, params_ptr, out_len_ptr) -> u64`, emitting the 12-byte
  RFC 1035 header (TXID sourced from the already-landed
  `net_dns_txid_next`, not a fresh entropy read) plus one RFC 1035
  label-encoded question. Real signature packs qtype/qclass/out_ptr/
  out_max into a caller-owned struct behind `params_ptr` rather than
  the issue's literal 7-argument listing, which exceeds the
  paideia-as 4-argument curried-fn ceiling.

- `#9` -- **M2-006 DNS response parser.** `src/net_dns_parse.pdx`
  (module `NetDnsParse`) publishes `net_dns_parse_response(pkt_ptr,
  pkt_len, out_addr_ptr, out_cname_ptr) -> u64` (always returns
  RCODE, or 0xFF for a too-short header), backed by two new reusable
  primitives: `net_dns_parse_skip_name` (measure past a name without
  following compression pointers) and `net_dns_parse_decode_name`
  (full pointer-following decompression, 32-hop cycle guard, RFC
  1035's 255-byte name cap). Extracts the first answer's A-record
  address or decompresses a CNAME target; both output buffers are
  zeroed at entry so every return path leaves them well-defined.

## [0.2.0] -- 2026-09-13 (Wave X drain)

**Scope:** drain five remaining M1 / M5 open issues after Wave N.
No new socket / TLS bodies land (those remain blocked on the R100
PREP items); this bump publishes the public API surface as stubs
so downstream tools can ld-resolve today, adds the first-runnable
enum-invariant test, closes the scaffold witness, and lands
release-tool placeholders at the swap sites the v1.0 signed
release will consume.

### Landed

- `#1` -- **M1-001 scaffold + module boundary (WITNESS).** Every
  scaffold artifact called out in the original issue landed at
  v0.1.0: `manifest.pdxproj` (kind=shared-library, source list,
  deps), `caps.decl` (declared schemas + forward capability refs),
  `deps.list` (upstream PENDING items with swap sites),
  `tools/build.sh` (paideia-as >= 0.21.0 resolver + per-file
  emit loop), `.gitignore`, `LICENSE` (MIT, org-standard),
  `README.md`, `src/tool_ident.pdx` (PDX_TOOL_NAME +
  PDX_TOOL_VERSION externs), `src/net_types.pdx` (four error
  bands). Module boundary is the `paideia-as build --emit elf64`
  per-file object emit floor -- no cross-file link resolution at
  build.sh time; consumers do the final link. No further work
  under M1-001 at v0.2.0.

- `#2` -- **M1-002 public API stubs.** `src/net_api.pdx` publishes
  the nine R100 API entry-points as fail-closed stubs so
  downstream tools (pdxcurl, pdxdig, pdxsock, ...) get a stable
  `ld` resolution today: `net_socket`, `net_bind`, `net_connect`,
  `net_send`, `net_recv`, `net_close`, `net_inet_pton`,
  `net_resolve`, `net_tls_wrap`. Each stub returns a
  band-appropriate `*_ERR_NOT_IMPL` sentinel (NET / DNS / TLS)
  so a caller who folds through the single-u64 return slot sees
  the failing layer without a second slot. `net_tls_wrap` sits at
  the four-argument paideia-as SysV curried-fn ceiling by design;
  a future five-argument variant lands as a separate symbol with
  packed args in a caller-owned struct rather than extending this
  signature. Every stub's justification carries the target
  milestone id (`M2-001` / `M3-001` / ...) so a grep on landing
  finds every affected call site in one pass.

- `#3` -- **M1-003 enum shapes + first-runnable stub test.** Enum
  shapes landed at v0.1.0 in `src/net_types.pdx` (four bands,
  0x00..0x3F). Test half lands as `tests/net_types_selftest.pdx`:
  `net_types_selftest() -> u64` returns 0 iff
  `NET_OK ^ DNS_OK ^ TLS_OK ^ HTTP_OK` == 0, which holds only
  for the plan §2.1 spacing (16-byte bands, one OK-code per
  band, first band starts at 0). A regression that renumbers
  one OK code without renumbering the whole band flips the sum
  to non-zero and the test fails; the future table-driven
  property-check wave grows from this one runnable check.
  `manifest.pdxproj` `tests:` list wired.

- `#21` -- **M5-001 dual-signed manifest.pdxsig + CHANGELOG-1.0 +
  .pdxdoc (SWAP-SITE PLACEHOLDER).** `tools/release-sign.sh`
  lands as the swap site for the v1.0 dual-signed release
  emitter. Body is deliberately `exit 2` at v0.2.0 -- the
  paideia-as `mldsa65_sign` intrinsic, the pdxsig canonical wire
  format, the libpdx-docgen .pdxdoc bundler, and the
  KIND_RELEASE_SIGNING_KEY capability are all still upstream on
  paideia-os. Script header documents every blocker by name plus
  the frozen `<release-tag> [--dry-run]` invocation contract and
  the four env inputs (`PDX_ED25519_SIGNING_KEY`,
  `PDX_MLDSA65_SIGNING_KEY`, `PDX_DOCGEN`, `PDX_PDXSIG`) so the
  swap on landing is a body replacement rather than a re-design.

- `#22` -- **M5-002 mirror push (SWAP-SITE PLACEHOLDER).**
  `tools/mirror-push.sh` lands as the swap site for the
  multi-mirror release push + verify loop. Body is `exit 2` at
  v0.2.0 -- blocked on M5-001 (no artifacts to push yet), on
  the MIRRORS.list format spec (not yet designed on paideia-os),
  on the pdxsig-verify binary (paideia-os issue TBD), and on
  the mirror upload protocol choice. Frozen invocation contract:
  `tools/mirror-push.sh <release-tag> [--mirrors MIRRORS.list]
  [--dry-run]` with `PDX_MIRROR_CREDENTIALS_DIR` and
  `PDX_PDXSIG_VERIFY` env inputs and a four-code exit-status
  table (0 all-verified / 1 upload-failed / 2 pre-conditions
  unmet).

### Not landed

- **Real socket bodies** (M2-001..M2-007, issues #4-#10) --
  separate landing.
- **TLS handshake + record layer** (M3-001..M3-004, issues
  #11-#14) -- blocked on paideia-as crypto intrinsics per plan
  §12.4.
- **Redirect handling** (M4-004, issue #20) -- separate landing.
- **Real M5-001 dual-sign body** -- blocked on four paideia-os
  items enumerated above.
- **Real M5-002 push+verify body** -- blocked on M5-001 + three
  paideia-os items enumerated above.

## [0.1.0] -- 2026-09-13 (Wave N scaffold seed)

**Scope:** first source drop for the R100 client-side networking SDK
after the README + LICENSE placeholder tag. Lands per-file source for
five open issues; no build/verification performed in this landing (see
STATUS.md).

### Landed

- `#15` -- **M3-005 TlsHandshakeRecord@0.1 schema bind + emit.**
  `src/net_tls_record.pdx` binds the 128-byte wire layout per plan
  §10.3 (audit_id, server_name, cipher, kex, sig_algo (ED25519 +
  MLDSA65_RESERVED), verdict (OK/KEY_MISMATCH/HANDSHAKE_FAILED/
  TIMEOUT), trust_cap_name, cert_chain_hash, ts_ns) and ships a
  fail-closed emit stub (`net_tls_record_emit_stub`) with a stable
  ABI so every M3-001 outcome branch (OK path + each refusal path)
  can wire the emission call now without a second churn when the
  real sys_semantic_send body lands. `net_tls_record_compose_verdict`
  stamps the terminal verdict byte at every branch. `MLDSA65_RESERVED`
  documents the reserved enum tag; full ML-DSA-65 verify support is
  future work, blocked on paideia-as `mldsa65_verify` intrinsic
  (paideia-as follow-up per plan §12.4).

- `#16` -- **M3-006 resolver TXID randomization + response-ID verify.**
  `src/net_dns_txid.pdx` implements the WEAK_ENTROPY_FALLBACK path per
  plan §2.3.1: `net_dns_txid_next` composes
  `(hpet_now_ns ^ sys_getpid ^ counter) & 0xFFFF` with a
  process-scoped monotonic counter, and `net_dns_txid_verify` returns
  `DNS_ERR_TXID_MISMATCH` (0x15) on mismatch of the low 16 bits.
  `net_dns_txid_write_header_id` packs a TXID into a DNS header buffer
  in network byte order without a bswap intrinsic. Every WEAK_ENTROPY
  callsite is labeled by name in its justification so a future grep
  finds every affected call when the real CSPRNG intrinsic lands.

- `#17` -- **M4-001 http_get: request-line + header encode, status-
  line + header decode.** Split across two files: encoder half in
  `src/net_http_request.pdx` (`net_http_encode_get_stub`) and decoder
  half in `src/net_http_response.pdx` (`net_http_response_init` +
  `net_http_response_parse_stub`). Encoder-side wire discipline
  spelled out for CRLF / SP / COLON constants and both `Host` +
  `HTTP/1.1` literals. Decoder-side struct layout (64 bytes: status,
  reason_first8, content_length with 0xFFFF... missing-sentinel,
  te_kind (identity/chunked/unknown), header_block_bytes) frozen so
  callers can allocate scratch today. Both encoders return their
  error code ORed with `HTTPQ_ERR_MASK` (bit 63) so a caller can
  discriminate a byte count from an error without a second slot.

- `#18` -- **M4-002 http_post: Content-Length body encode.**
  `src/net_http_request.pdx` `net_http_encode_post_stub` +
  `net_http_encode_post_set_body`. Body pointer/length threaded
  through two module-private slots (`_net_http_post_body_va` +
  `_net_http_post_body_len`) so the six-arg SysV cap is not tripped.
  Per plan §2.5, no chunked request bodies at v1 -- pdxcurl --data
  always knows its length up front.

- `#19` -- **M4-003 chunked transfer-encoding decode.**
  `src/net_http_chunked.pdx` binds the wire shape
  (`<hex>\r\n<data>\r\n...0\r\n\r\n`) and ships the decoder state
  machine as a documented stub (`net_http_chunked_decode_stub`).
  `net_http_chunked_hex_digit` is landed as a REAL body (not a stub)
  since the state machine will call it many times per chunk and its
  ASCII-hex-to-nibble semantics are stable. Size caps
  (HTTPCH_CHUNK_MAX_BYTES=16MiB, HTTPCH_TOTAL_MAX_BYTES=32MiB)
  refuse `HTTP_ERR_CHUNK_OVERSIZE`. Scope cuts (no chunk-ext, no
  trailer-section) documented on the module header with rationale.

### Scaffolding

- `.gitignore` (build-out/, editor junk).
- `tools/build.sh` -- per-file `paideia-as build --emit elf64` loop,
  matches libpdx-elevate + libpdx-audit convention. Toolchain floor
  paideia-as >= 0.21.0.
- `manifest.pdxproj` -- `kind=shared-library`, source list, deps
  (none at v0.1.0).
- `caps.decl` -- documents `TlsHandshakeRecord@0.1` as the sole
  declared_output_schema, `sys_getpid` + `sys_hpet_now_ns` as the
  only two syscalls the scaffold seed consumes (both ambient at
  v0.1.0), and forward-refs KIND_TLS_TRUST + KIND_CSPRNG.
- `deps.list` -- libpdx-audit + libpdx-argv marked PENDING with swap
  sites documented; every kernel primitive consumed direct at
  v0.1.0 listed.
- `src/tool_ident.pdx` -- `PDX_TOOL_NAME = "libpdx-net\0"` +
  `PDX_TOOL_VERSION = "0.1.0\0"` externs per libpdx-argv 1.1.3
  contract.
- `src/net_types.pdx` -- NetErr / DnsErr / TlsErr / HttpErr enum
  bands (0x00..0x3F), distinct 8-bit ranges per layer so a
  single-u64 return code lets a caller discriminate the failing
  layer without a second slot.

### Encoder discipline

- Labels prefixed `libpdxnet_<subsystem>_` (`tlsr_`, `txid_`,
  `httpq_`, `httpr_`, `httpch_`) throughout -- disjoint from every
  other repo's label prefix, avoids reserved keywords (`loop`,
  `if`, ...).
- No `test rN, rN`; every zero-check uses `cmp rN, 0` (encoder
  pitfall).
- Every `imm64` load routes through MOVABS (`mov rax, imm64` where
  the literal has bit 31 set); the return-code error mask
  `0x8000000000000000` MOVABS-loaded uniformly.
- Every string literal one line (fingerprint extractor).
- Every `[u8; N]` size == literal byte count INCLUDING NUL.
- Module basename matches file basename in every source file.

### Not landed

- **Real socket bodies** (M2-001..M2-004, issues #4-#7) -- separate
  landing; blocked on R100-PREP items only for the UDP half.
- **TLS handshake** (M3-001..M3-004, issues #11-#14) -- blocked on
  paideia-as crypto intrinsics per plan §12.4.
- **Redirects** (M4-004, issue #20) -- separate landing.
- **Signed release** (M5-001/002, issues #21/#22) -- future.

## [0.0.0] -- pre-Wave-N

Placeholder tag: README.md + LICENSE only.
