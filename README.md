# libpdx-net

Client-side networking SDK for PaideiaOS user-space tools. Ships TCP/UDP socket wrappers, endian helpers, dotted-quad address parse, a minimal DNS stub resolver, a TLS 1.3 client (raw public keys per RFC 7250, no X.509, no CA store), and an HTTP/1.1 client (chunked decode, redirect handling). The one library every other R100 CLI links, except `libpdx-url` (which it consumes).

## Spec

Full design lives in the paideia-os monorepo at
[`design/networking/r100-user-tools-plan.md`](https://github.com/paideia-os/paideia-os/blob/main/design/networking/r100-user-tools-plan.md)
(softarch's R100 user-tools plan). Section references in issues point into that document.

This repository is one of seven satellite repos that together deliver the
R100 wave: `libpdx-net`, `libpdx-url`, `pdxcurl`, `pdxping`, `pdxdig`,
`pdxsock`, `pdxtrust`.

## License

MIT.