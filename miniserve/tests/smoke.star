# Stable smoke test — assert on the contract (exit codes, version shape,
# computed output, stable API tokens), never on help/version prose.
#
# ⚠️ NO LEG MAY EVER START THE SERVER. miniserve's whole job is to bind a
# socket and block forever; `ocx.run` is a blocking spawn with no background
# mode, and the Starlark host exposes no HTTP client (there is no
# `ocx.http.get`), so a serve-then-fetch test cannot be expressed here — it
# would simply hang every leg until the job timeout. Every invocation below is
# therefore one miniserve exits from on its own: two code-generating modes that
# never touch the network, and three argument/IO failure paths.
#
# The end-to-end serve path WAS verified out of band before this mirror shipped
# (v0.35.0 musl artifact, `-i 127.0.0.1 -p <ephemeral> <dir>`, fetched
# `hello.txt` back byte-for-byte) — it is the harness that cannot host it, not
# the artifact that is unproven.
#
# ⚠️ `expect.eq(r.stdout, "")` ON EVERY FAILURE PATH IS LOAD-BEARING. miniserve
# announces a successful bind on STDOUT:
#
#   miniserve v0.35.0
#   Bound to 127.0.0.1:41347
#   Serving path /tmp/…
#
# so an empty stdout on those runs is positive proof the listener never came
# up and the process died on the argument/IO error it was given, rather than
# racing into a serve that the runner would then have to kill.

MINISERVE = "miniserve.exe" if ocx.target_platform.os == ocx.os.Windows else "miniserve"

# ─── Tier 1 + 2: liveness + version SHAPE (never the digits, never a vendor
# string). Both ends of the mirrored range answer here (0.33.0 and 0.35.0).
r_version = ocx.run(MINISERVE, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# Taken FROM THE ARTIFACT, not hard-coded — this is the value the cross-check
# below compares an independent code path against.
VERSION_LINE = r_version.stdout.strip()

# ─── Tier 3a: roff CODEGEN, cross-checked against `--version`.
# `--print-manpage` walks the real clap command tree and emits a man page; the
# structural `.TH` header is API, not prose. Asserting that the version it
# stamps equals the one `--version` reports makes two independent code paths
# agree on the artifact's identity — something a truncated download or a
# wrong-version binary cannot fake.
r_man = ocx.run(MINISERVE, "--print-manpage")
expect.ok(r_man)
expect.matches(r_man.stdout, r"\.TH miniserve 1\s+\"miniserve \d+\.\d+\.\d+\"")
expect.contains(r_man.stdout, VERSION_LINE)

# ─── Tier 3b: shell-completion CODEGEN, per shell.
# Generating for two different shells and asserting the outputs DIFFER proves
# the generator actually ran per target rather than echoing one canned blob.
# `_miniserve` (bash function name) and `#compdef miniserve` (zsh header) are
# the names the user's shell calls — API, not help text — and `--port` is a
# flag from the same command tree the man page above was built from.
r_bash = ocx.run(MINISERVE, "--print-completions", "bash")
expect.ok(r_bash)
expect.contains(r_bash.stdout, "_miniserve")
expect.contains(r_bash.stdout, "--port")
expect.true(len(r_bash.stdout) > 2000)

r_zsh = ocx.run(MINISERVE, "--print-completions", "zsh")
expect.ok(r_zsh)
expect.contains(r_zsh.stdout, "#compdef miniserve")
expect.ne(r_bash.stdout, r_zsh.stdout, msg = "completions must be generated per shell, not echoed")

expect.ne(r_man.stdout, r_bash.stdout)

# ─── Tier 3c: HERMETIC FILE READ. `--auth-file` is the one non-serving path
# that makes miniserve open and parse a file we authored. Two files, identical
# invocation otherwise, both aimed at a directory that does not exist:
#   • well-formed credentials  → parsing succeeds, the run dies later, at path
#                                resolution
#   • malformed credentials    → the run dies earlier, in the credential parser
# The failure texts are upstream prose and are NOT asserted; that they DIFFER
# is the contract — it can only differ if the bytes we wrote were actually read
# and interpreted.
ocx.write_file("good.auth", "joe:sha256:a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3\n")
ocx.write_file("bad.auth", "this-line-has-no-colon-at-all\n")

r_auth_ok = ocx.run(MINISERVE, "--auth-file", "good.auth", "ocx-smoke-absent-dir")
r_auth_bad = ocx.run(MINISERVE, "--auth-file", "bad.auth", "ocx-smoke-absent-dir")
expect.ne(r_auth_ok.exit_code, 0)
expect.ne(r_auth_bad.exit_code, 0)
expect.eq(r_auth_ok.stdout, "", msg = "server must not bind on a missing serve path")
expect.eq(r_auth_bad.stdout, "", msg = "server must not bind on a malformed auth file")
expect.ne(r_auth_ok.stderr, r_auth_bad.stderr, msg = "auth file contents must change the outcome")

# ─── NEGATIVE CONTROLS. Green above is only evidence if red is reachable.
# An unknown flag must be rejected by the argument parser, and a serve path
# that does not exist must be rejected by path resolution — neither may fall
# through into a listening server.
r_badflag = ocx.run(MINISERVE, "--ocx-smoke-not-a-real-flag")
expect.ne(r_badflag.exit_code, 0, msg = "unknown flag must not be accepted")
expect.eq(r_badflag.stdout, "")

r_nopath = ocx.run(MINISERVE, "ocx-smoke-no-such-directory")
expect.ne(r_nopath.exit_code, 0, msg = "nonexistent serve path must not start a server")
expect.eq(r_nopath.stdout, "")
