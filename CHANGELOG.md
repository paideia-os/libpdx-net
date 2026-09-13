# libpdx-net -- CHANGELOG

All notable changes to this repository are documented here. Versioning
follows SemVer with a v0.x series until the M5 signed release.

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
