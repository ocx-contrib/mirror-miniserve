# NOTICE

This repository packages and redistributes upstream software published by the
[miniserve project](https://github.com/svenstaro/miniserve). The Apache-2.0
license in [`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It
does **not** cover any upstream-derived asset — each package's redistributed
bytes carry their own license, recorded below.

Each package's logo is reproduced for catalog identification only. The marks
remain the property of their respective owners and no endorsement is implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `miniserve` | `ghcr.io/ocx-contrib/miniserve/miniserve` | `MIT` |

---

## `miniserve`

Upstream: <https://github.com/svenstaro/miniserve>
Published to `ghcr.io/ocx-contrib/miniserve/miniserve`.

| Component | SPDX | Holder |
|---|---|---|
| miniserve (`miniserve`) | **MIT** | Copyright (c) 2019 Sven-Hendrik Haase and contributors |

Permissive; redistribution of the compiled binary is granted provided the
copyright notice and permission notice are retained. Upstream ships raw
binaries with no bundled `LICENSE` file, so the notice is reproduced above and
the terms are those of
<https://github.com/svenstaro/miniserve/blob/master/LICENSE>. The published
binaries statically link third-party Rust crates under permissive licenses,
enumerated in upstream's `Cargo.lock`.

The `logo.svg` / `logo.png` shipped with this package are the official
miniserve logo (`data/logo.svg` in the upstream repository), covered by the
same MIT license as the project.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle. Upstream itself compresses the
Linux and Windows binaries with [UPX](https://upx.github.io/) before publishing
them — that is upstream's packaging, not a transformation applied here.
