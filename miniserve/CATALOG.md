---
title: miniserve
description: Single-binary CLI that serves a file or directory over HTTP right now, with uploads, auth, TLS, archives and WebDAV
keywords: miniserve,http,http-server,file-server,static-server,webdav,upload,cli,rust
---

# miniserve

miniserve is a small command-line utility that serves a file or a directory
over HTTP with one command — `miniserve ./some-dir` — and nothing to configure.
It renders a sortable directory listing, streams single files directly, and
shuts down when you do.

Beyond the basic listing it can accept uploads (`--upload-files`) and directory
creation (`--mkdir`), require HTTP basic auth from a plaintext or hashed
credential (`--auth`, `--auth-file`), terminate TLS itself (`--tls-cert` /
`--tls-key`), hand out whole directories as `.tar`, `.tar.gz` or `.zip`
(`--enable-tar`, `--enable-tar-gz`, `--enable-zip`), serve an index file for
SPA routing (`--index`, `--spa`), speak WebDAV (`--enable-webdav`), and print a
QR code of its own URL for phones on the same network (`--qrcode`).

## What's included

- **miniserve** — the single static binary. `miniserve --version`,
  `miniserve <path>`, `miniserve --print-completions <shell>`,
  `miniserve --print-manpage`. No runtime dependencies.

## Links

- [miniserve on GitHub](https://github.com/svenstaro/miniserve)
- [Usage and flags](https://github.com/svenstaro/miniserve#usage)
- [Changelog](https://github.com/svenstaro/miniserve/blob/master/CHANGELOG.md)
