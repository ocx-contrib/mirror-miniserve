# mirror-miniserve

OCX mirror for [miniserve](https://github.com/svenstaro/miniserve). One
repository, one spec directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [miniserve](https://github.com/svenstaro/miniserve) | [`miniserve/mirror.yml`](miniserve/mirror.yml) | `ghcr.io/ocx-contrib/miniserve/miniserve` | [`ocx.sh/miniserve/miniserve`](https://index.ocx.sh/miniserve/miniserve) | `MIT` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

`svenstaro` is a maintainer's personal handle rather than a vendor or a project
brand, so under the namespace rules the tool names itself: `miniserve/miniserve`.

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
miniserve/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — each
package carries its own, because a repo-root `logo.*` sits in no workflow's
`paths:` filter, so replacing it would publish nothing until some unrelated
edit happened to fire.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. Restate a block in full or
not at all.

## Platforms

`miniserve` publishes five platform entries: both Linux arches, both macOS
arches and `windows/amd64`.

**No `windows/arm64`.** Upstream builds no aarch64 Windows target — its two
Windows assets are `x86_64-pc-windows-msvc.exe` and `i686-pc-windows-msvc.exe`
(verified on v0.33.0, v0.34.0 and v0.35.0). Declaring it would match zero
assets, which the pipeline silently skips: a green run with a phantom platform.
`i686` has no OCX architecture key, so `windows/amd64` is the complete Windows
surface.

**No FreeBSD or illumos.** Upstream also ships `x86_64-unknown-freebsd` and
`x86_64-unknown-illumos`; neither is an OCX operating system and neither has a
GitHub-hosted runner, so neither can be built or tested.

Upstream's `arm-unknown-linux-musleabihf`, both `armv7-…` targets and
`riscv64gc-unknown-linux-gnu` are upstream assets, not declarable platforms —
OCX's architecture enum is amd64 and arm64 only.

## The libc claim, and why `readelf` alone gets it wrong here

Upstream ships **both** a gnu and a musl build for each Linux arch, and this
mirror carries the **musl** one under a **bare** platform key — no `+libc.*`
suffix — because it is fully static and therefore requires nothing of the host.

Getting there needs one extra step compared to a normal Rust mirror. Every
Linux and Windows asset is **UPX-compressed** by upstream's release workflow,
and the packer's stub has no `PT_INTERP`, no `PT_DYNAMIC` and no section
headers — so `file` reports *every* Linux asset as "statically linked",
including the glibc-dynamic ones. `upx -d` first, then measure:

| Unpacked asset | `PT_INTERP` | `DT_NEEDED` | Verdict |
|---|---|---|---|
| `…-x86_64-unknown-linux-musl` | none | none | static |
| `…-aarch64-unknown-linux-musl` | none | none | static |
| `…-x86_64-unknown-linux-gnu` | present | `libc.so.6`, `libm.so.6`, `libgcc_s.so.1` | glibc ≥ 2.34 |
| `…-aarch64-unknown-linux-gnu` | present | same | glibc ≥ 2.34 |

Confirmed by running each artifact under all three container userlands
(`--version`, v0.35.0 and v0.33.0, both arches): the musl builds exit 0 on
`ubuntu:24.04`, `fedora:40` **and** `alpine:3.20`; the gnu builds exit **127**
on alpine, with no loader. The `alpine:3.20` legs in `mirror-base.yml` are what
turn the bare key into evidence — and they demonstrably red against the wrong
artifact, so a green there is a reached red rather than a habit.

The gnu builds are deliberately not carried. A second `+libc.glibc` key is the
fallback, not the goal; it earns its place where the gnu build reaches
capability the static one lacks, and the usual differentiator — musl's
NSS-blind resolver — does not apply to an inbound file server that binds an IP
and resolves no hostnames.

## Why the smoke test never starts a server

miniserve's job is to bind a socket and block. `ocx.run` is a blocking spawn
with no background mode, and the Starlark host exposes no HTTP client, so a
serve-then-fetch assertion cannot be written — it would hang every leg until
the job timeout.

`miniserve/tests/smoke.star` therefore drives only paths miniserve exits from
on its own: `--print-manpage` and `--print-completions` (real codegen over the
same clap command tree, cross-checked against `--version` and against each
other), plus three failure paths — malformed credentials, an unknown flag, and
a nonexistent serve path. Each failure path also asserts **stdout is empty**,
which is positive proof the listener never came up: miniserve prints
`Bound to <addr>` / `Serving path <p>` on stdout the moment it binds.

The end-to-end serve path was verified out of band before this mirror shipped
(bind `127.0.0.1` on an ephemeral port, fetch a known file back byte-for-byte)
— it is the harness that cannot host that check, not the artifact that is
unproven.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `miniserve/mirror.yml` | hand | yes — see below |
| `miniserve/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `miniserve/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec miniserve/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## The binaries claim

miniserve ships as a raw binary, so the bundle's only PATH entry is a bare
`${installPath}` — the executable *is* the content root. `bin_scan` only looks
*below* an `${installPath}/<dir>` entry, so `auto`/`verify` is rejected at spec
load with exit 65. `mirror-base.yml` therefore sets `bin_scan: "off"` and
`miniserve/metadata.json` hand-lists `binaries: ["miniserve"]`.

That list is doubly load-bearing here: GitHub serves these raw assets **without
the exec bit** (mode 0644 as downloaded), and `prepare` chmods only the
binaries the metadata declares. Drop the name and the bundle ships an
unexecutable file.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; each
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
