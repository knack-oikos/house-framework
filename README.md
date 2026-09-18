# house-framework

**The starting point of a house of agents.**

For anyone who runs a roster of agents against a repository — under any
agent harness, or none — and wants the rules, the roster, the queue and the
checks in place before the first agent wakes. It runs on git, bash and
`mise`, and it is not tied to the household that wrote it.

A *house* is a directory where a roster of agents wake, read their rules,
take work from a queue, and return. `house init` gives you one: a contract
that says what an agent may do without asking and what only you decide, a
roster, a work queue, a commit guard that refuses an author who is not on
the roster, a housekeeper that keeps the record true, and a set of checks.
`house agent add` puts an agent on it, `house rules add` drops in a domain
rule set, and `house doctor` measures the house against the shape every
house shares. The command is `house`.

house-framework is [MIT-licensed](LICENSE). A house rendered from its
templates belongs to whoever generated it and is not bound by the
framework's license.

A house does not depend on any agent harness. Everything it generates is
markdown, bash, git and `mise`; a runner gets its agent definitions from a
separate `house export <harness>` step that reads the roster and can be
re-run or ignored.

A house starts small, and starts empty: the shape is the framework's, the
words are yours. `init` renders the authority model whole and leaves every
question it cannot answer for you — what the house is, who owns it, how you
merge, the house style, the first backlog entries — as a
`<!-- house:decide: … -->` marker, and `house doctor` fails until you have
answered each one. Each larger capability — encrypted notes, per-agent
accounts and keys, mail, chat, CI wakes — is yours to file and switch on,
and a dated widening in the contract when you do.

## Prerequisites

To run `house`:

- bash 4 or newer, first on `PATH`
- [git](https://git-scm.com) 2.28 or newer, with `user.name` and `user.email`
  set: `house init` makes a bootstrap commit
- curl, jq, CA certificates for HTTPS, and `sha256sum` or `shasum`: shiv's
  installer refuses without curl, git and jq; mise's installer checks its
  download with a sha tool; the `house` shim resolves `house agent add` to
  `agent:add` through jq
- [shiv](https://github.com/KnickKnackLabs/shiv), which installs
  [mise](https://mise.jdx.dev) if it is absent; mise runs every `house`
  command, and `mise install` in the clone brings
  [bats](https://github.com/bats-core/bats-core), the test runner, from the
  registry `mise.toml` names — the one tool the clone declares

To live in a house: git, bash and mise. A generated house's own tasks never
call shiv, and `house doctor` checks the list above — the bash and git
versions, the git identity, mise and jq on `PATH` — and prints the fix for
each line it fails.

The list is established, not asserted: on every pull request, a CI job
starts from a `debian:stable-slim` image with only those packages, runs the
shiv installer, installs `house` from the checkout under test, and runs
`house init` and `house doctor` there.

## Install

```bash
curl -fsSL shiv.knacklabs.co/install.sh | bash   # installs mise too, if absent
mkdir -p ~/.config/shiv/sources                  # source file: see below
echo '{"house": "olavostauros/house-framework"}' > ~/.config/shiv/sources/house.json
MISE_JOBS=1 shiv install house                   # serial: see below
house --version
```

Restart the shell once after the first line: the installer adds a line to
your shell rc and needs it. The source file is needed until `house` is in
shiv's own index
([KnickKnackLabs/shiv#176](https://github.com/KnickKnackLabs/shiv/pull/176)
is the request): without it, `shiv install house` stops at `'house' not
found in package index`. Once that merges, the two source-file lines go; a
fork under another name stays the same one line away from being installable
as `house` for its owner.

Bare `shiv install house` takes the newest release tag; `shiv install
house@main` tracks `main`, `shiv install house@v0.1.0` pins, and `shiv
update house` moves an install to the newest release. `house --version` is
what a bug report quotes: the tag at the install's `HEAD`, else its short
commit, then the branch and the age of the last commit. `house version` is
the same tag or short commit from the inside, and it is what a house
records when it is made.

Three things to know about the chain before running it. The installer
`eval`s a terminal-UI library fetched over the network at run time, and
falls back silently when the fetch fails. The installer does not install
shiv's own tools; the first `shiv` command does, and two of them
(`shiv:codebase`, `shiv:readme`) race on the backend's clone when mise
installs them side by side
([KnickKnackLabs/vfox-shiv#22](https://github.com/KnickKnackLabs/vfox-shiv/issues/22)),
which on a clean machine fails every time — `MISE_JOBS=1` on that first
command serializes them, and the CI job below runs the chain that way. And
those two are floating `shiv:` ranges in shiv's own `mise.toml`, the shape
`house doctor` warns about in a *global* mise config; they are shiv's, not
a house's, and `doctor` does not read them.

### From a checkout

```bash
git clone https://github.com/olavostauros/house-framework
cd house-framework && mise trust && mise install
```

`mise trust` is asked once, because `mise.toml` sets tool and task settings
for this directory. Every `house` command in this README is a `mise run`
task of this checkout (`house init` is `mise run init`, `house agent add` is
`mise run agent:add`, `house version` is `mise run version`), which is how
CI runs it:

```bash
mise run init example --at /path/to/example
```

To put a working clone on `PATH` as `house` — the way to try the shim
against a branch — register the checkout itself as a local-path package:

```bash
shiv install house "$PWD"
```

## Quick start

```bash
# A house inside the project it works on
house init example --at ~/project/example --embedded

# A house that is a repo of its own and works on other repos
house init example --at ~/example --owner 'Your Name'

# The same, on encrypted notes and shimmer (exact shiv pins, opt-in)
house init example --at ~/example --with notes,shimmer

# The same, with the strict style rendered as notes/house-style.md
house init example --at ~/example --style strict

cd ~/project/example
house agent add builder --role implementation --owns src/ \
  --charge 'Builds what the queue asks for, under src/.'
house agent add judge --role review \
  --charge 'Reads every pull request into main before the owner merges it.'
house rules add data --binds builder
house rules add review --binds judge

mise run install-hooks
mise run welcome
house doctor            # fails, naming each house:decide marker, until the house is yours

# Only if the agents run under a harness that has an exporter
house export <harness>
```

Where the shape came from is history, kept in git and nowhere in the tree:
the bootstrap commit names the households it was distilled from, and
`lib/lineage-names` lists them only so `doctor` can reject them in a house.

## What `init` writes

| Path | What it is |
|---|---|
| `AGENTS.md` | the contract: what the house is (a marker, for the owner), who owns it, the roster, three rules that protect the guard and the shared checkout, a slot for domain rule sets, the tiers, the loosenings table, the two-key rule, the Read-first table |
| `roster.tsv` | who counts as an agent, with role, owned directory and kind — read by the guard, `agent-env`, `welcome`, `doctor` and every exporter |
| `notes/work-queue.md` | the owner files entries here, each addressed to one agent |
| `notes/household-backlog.md` | Tier 2 proposals; empty but for a marker asking which changes this house wants first |
| `hooks/agent-identity` | pre-commit guard: refuses an author not on the roster unless `<HOUSE>_OWNER_COMMIT=1` |
| `.mise/tasks/{welcome,test,agent-env,install-hooks}` | the task surface; `agent-env` sets `<name>@<house>.invalid` as the git author, a label on a reserved name that claims no domain |
| `test/*.bats` | the house's own checks, roster-driven so they stay true as agents join |
| `mise.toml`, `README.md`, `.gitignore` | the rest; the README carries the one line of attribution a house keeps, `Started from house-framework on <date>, at <version>` — the version `house version` printed when the house was made, which `house doctor` reads back against the version checking it |
| `--owner <name>` | who the owner is, in the contract; defaults to git `user.name`, and to a marker when that is unset |
| `--style <name>` | opt-in: a house style — review, merge, comment, PR size, what a session leaves behind — as `notes/house-style.md`, wired to Read-first and named in the bootstrap commit. `strict` is the one that ships: small branches, merges that keep history, nothing unpushed or undocumented. Without it the contract asks the owner for a style and has none |
| `--with notes,shimmer` | opt-in: each named package as an exact `shiv:` pin plus `[plugins] shiv`, its wiring (`agent:list` for shimmer), its bats file, and the contract, README and backlog rewritten where the package makes them false; without the flag nothing changes |

A standalone house gets its own repo and a bootstrap commit, which is where
the framework's name goes. An embedded house is a directory of the project
repo; you commit it as the owner.

## Making it yours

A fresh house is not `healthy`, on purpose. `house doctor` fails on every
`<!-- house:decide: … -->` marker, every leftover `{{KEY}}`, every agent
Stance the owner has not written, and every name of a household the
framework grew out of (the list is `lib/lineage-names`; `KnickKnackLabs`
outside a tool pin is added unless a preset declared the package) — each
with its file and line. Answer each marker in the text around it and delete
the comment; write each agent's Stance in `notes/<name>.md`; then `doctor`
reports `healthy`. The house's own name and project are never counted, so a
house that happens to share a name with one of those passes.

What `init` produces, before any of that, is [`examples/`](examples/): a
standalone house named `example` at `~/example` with the housekeeper and
one added agent, `builder`, plus the housekeeper's home under
`~/agents/example/` — `~/agents` is the default root for agent homes, and
`HOUSE_AGENTS_ROOT` moves it. It is rendered with a fixed date and a fixed
framework version (`v0.0.0`) so that the bytes do not move between commits,
regenerated by `mise run examples --write` and compared with a fresh render
by `mise run test`, so the table above is checked, not described.

A preset never overwrites a file that exists, and these two never widen the
contract (a preset for a channel such as chat or mail would, as a dated
loosening row under the owner's name):
`notes` declares the package and rewrites the shared-notes clause, but the
encryption itself is `notes setup --gpg-key <fingerprint>`, the owner's
step, which `init` names and `house doctor` fails without. `shimmer` is
declared and fed the roster through `agent:list`; `agent-env` stays the
identity, because `shimmer as` reads its token through a desktop keyring
and a house must not depend on one. `secrets` has no preset by that rule.

If your git config signs commits, `init` says so and names the key before
the passphrase prompt can appear, and `--no-commit` avoids it. Every house's
`mise run welcome` reports the same state, and the house README's *Signing*
section says what a signing machine means for the agents: their commits
carry the owner's key, and a stalled prompt is reported, never worked around.

## The housekeeper

Every house has exactly one, and it is always named `housekeeper`. `init`
adds it (skip it with `--no-housekeeper`, add it later with `house agent add
housekeeper`); a second one, or one under another name, is refused by `agent
add` and failed by `doctor`. Its work is standing and needs no filing: it
measures the queue, the backlog, the notes, the roster and the branches
against what is on disk, fixes verified-false facts in `notes/` on a local
branch, files everything else as a backlog proposal, and reports to the
owner in the session.

The housekeeper is the house speaking, so its identity is the house's. Its
home is `~/agents/<house>/home/`, not `~/agents/housekeeper/`, and a
harness definition exported for it is named after the house. Two houses on
one machine therefore never collide, and each keeps its own.

It carries **no GitHub account, no signing key and no mail, permanently.**
Its note and its home say so, and the contract excludes it from any identity
entry the owner files for the other agents. It reads GitHub through the
owner's login and writes nothing there; it pushes nothing. The record can be
trusted because the one agent whose job is the record has no voice outside
the house.

## What `agent add` writes

- a row on `roster.tsv`: name, role, owned directory, kind
- `notes/<name>.md`, the household-visible identity, with a Stance the owner
  writes before the agent first wakes — `doctor` fails until it is written
- a bullet under "Who lives here" and a row in the Read-first table
- `~/agents/<name>/home/` with `AGENTS.md`, `mise.toml`, `SCRATCHPAD.md`, as
  a local git repo — the agent's own startup contract, in the `AGENTS.md`
  convention any harness can read

Three kinds. `--owns <dir>/` makes a **builder**: takes queue entries, works
on `<name>/<topic>` branches under its directory, opens PRs, may edit and
write. Without `--owns` it is a **judge**: owns nothing, answers in the
written record, reads and researches but never patches. The name
`housekeeper` makes the one above. Whatever the kind, the owner merges and
the owner files the queue.

## Harnesses

Nothing above knows which runner the agents wake under. When one is in use,
`house export <harness>` projects the roster into that runner's agent
definitions, one per roster agent, mapping each kind to the tool set it
should have there. Exporters live under `templates/harness/<name>/` with a
matching `.mise/tasks/export/<name>` task, and are the only place a runner
is named; the first is `claude-code`, which writes
`~/.claude/agents/<name>.md` (`HOUSE_DEFINITIONS_DIR` or `--to` override the
directory).

An export keeps a definition that already exists unless `--force`. The
house contract makes every definition Tier 2, so the export is the owner's
to run and the agents' to propose against.

## Invariants

These hold in every house, and `house doctor` checks the ones a script can:

- **The contract is authority-only** and enumerated once. Tiers, loosenings
  and the owner-only list live in `AGENTS.md` and nowhere else; definitions,
  homes and notes link to them and never restate them.
- **Narrowing is the agent's; widening is the owner's**, in the owner's own
  turn, as a dated row in the loosenings table.
- **Relayed approval is not approval.** Only the owner's turn or a
  permission prompt is consent.
- **Nobody merges but the owner**, until a loosening says otherwise.
- **The roster is one file**, and the guard fails closed without it.
- **Homes are the agent's boundary**, not the house's: `agent add` creates
  them once and never overwrites them. Exported definitions are kept the
  same way.
- **The house is harness-agnostic.** `init`, `agent add` and `doctor` never
  read or write a runner's files; only an exporter does.
- **There is one housekeeper, named `housekeeper`, homed under the house's
  name.** It has no outward identity, and no upgrade path gives it one.
- **A fresh house is the owner's to finish.** Every question the framework
  cannot answer is a `house:decide` marker, `doctor` fails on each until it
  is answered, and no generated file names a lineage, a runner, or a
  toolchain outside a tool pin or a preset.

## Development

```bash
mise trust
mise install
mise run test                 # bats, template syntax, and examples/ against a fresh render
mise run examples --write     # after a template change; commit examples/ with it
mise run version              # what a house made from this checkout records
git diff --check
```

`test` and `examples` are hidden from the shim's surface (`hide = true` in
their headers), so `house test` is not a command and `mise run test` is;
the user-facing surface is `init`, `doctor`, `version`, `agent add`,
`rules add` and `export <harness>`. How a release is cut is in
[`CONTRIBUTING.md`](CONTRIBUTING.md).

The tests scaffold houses into temporary directories with `HOUSE_AGENTS_ROOT`
and `HOUSE_DEFINITIONS_DIR` pointed away from your real `~/agents` and from
any harness's definitions, and `examples` renders under a temporary `HOME`.
Nothing under your home is touched.

How to propose a change is in [`CONTRIBUTING.md`](CONTRIBUTING.md); what a
change must preserve is in [`AGENTS.md`](AGENTS.md).
