---
title: lineage
tags: [design, history]
created: 2026-09-16
updated: 2026-09-17
---

# Lineage

What house-framework kept from each of its three sources, what it dropped,
and why. Read this before changing a template, so a rule is not removed
because its reason was forgotten, and not kept because nobody remembered
that it was an accident.

## fold → oikos → agora → house-framework

**fold** (ricon-family, 2026) is the original: a shared home base where
twenty-odd agents wake, with the whole Knick Knack Labs toolchain declared
in `mise.toml` — `shiv` for packages, `shimmer` for identity and CI wakes,
`notes` for encrypted shared memory, `chat`, `emails`, `sessions`, `desks`,
`modules`. Its `AGENTS.md` is long and mixes rule with practice, and it
points at some forty notes through a trigger table.

**oikos** (olavostauros, 2026-08) forked fold for one household of two,
`knick` and `knack`, and grew the part fold did not have: an explicit
authority model. The tiers (free / propose / never), the two-key rule, the
loosenings table with its append-only and enumerated-once rules, the
owner-only list, and the refusal of relayed approval all come from oikos,
each one written after a real failure the note records. oikos also learned,
expensively, that a contract loaded whole by every agent every session
costs more than the work, and decided on 2026-09-03 that the contract holds
authority only and practice moves to trigger-read notes.

**agora** (2026-09-16, inside `olavostauros/ticket`) is oikos rebuilt for a
project rather than for upstream contribution: four agents each owning a
directory, a reviewer with no directory, the owner filing the queue, no KKL
tooling beyond `bats`, plaintext notes, the owner's `gh` login as transport,
and four domain rule sets — money, identity, data, review — that bind one
agent each. It is the smallest thing that is still a household.

**house-framework** takes agora's size as the default and oikos's authority
model as the invariant, and makes both generate.

## Kept

| From | What | Why |
|---|---|---|
| fold | the shape: home base, orient first, `mise welcome` as observational, the Read-first trigger table, `~/agents/<name>/home` as the private half | the split between *where we live* and *where we work* is the whole idea |
| fold | the mise task surface, BATS tests through `mise run`, `notes` frontmatter and wikilinks | ecosystem fit; a house can adopt any KKL package without changing shape |
| oikos | the tiers, the two-key rule, the loosenings table, Tier 3's refusal rule | each one is the fix for a recorded failure |
| oikos | "the contract is authority-only", "enumerated only here", "narrowing is yours, widening is the owner's" | satellite copies went stale twice and silently cancelled grants |
| oikos | the pre-commit identity guard with an owner-only escape hatch | 36 misattributed commits before it existed |
| oikos | three git rules in the contract — own your commits, prove the tree in the command that writes, stage by explicit path — and the rest of its practice as `templates/style/strict.md` | the three protect the guard and the shared checkout, which every house has; the rest is taste with a dated near-miss behind it, and a new house takes it only by asking (`--style strict`, the style's name being the practice, not the house) |
| agora | the embedded placement, directory ownership, the owner files the queue, no agent merges, the seam rule (interface one owns, call site another owns) | the smallest form that still separates authority from work |
| agora | `agent-env` instead of `shimmer as`, plaintext notes, the owner as transport | a house should wake on day one with `git`, `mise` and `bats` only |
| agora | the four rule sets | they are what turned a style guide into a contract |
| agora | the "what is not here yet" list, without its comparator | so the missing pieces read as choices, not gaps — and as this house's choices, not a comparison with another |

## Dropped, and why

- **The KKL toolchain as a requirement.** fold and oikos declare thirteen
  shiv packages; a fresh house declares one aqua tool, `bats`, and it comes
  from the Knick Knack Labs fork only because the standard aqua package does
  not run (`bats-exec-file: command not found`, measured 2026-09-17 on
  `aqua:bats-core/bats-core.14.0` and on mise's `bats` backend, which is
  the same package). Each package is a preset the owner asks for. The
  backlog no longer seeds anything: the two upgrades oikos took first were
  oikos's answers, and a house that is not on GitHub deleted them before
  the backlog was its own.
- **Hardcoded rosters.** agora repeats its four names in the hook, in
  `agent-env`, in `welcome` and in every test. house-framework puts them in
  `roster.tsv` and has everything read it, so `agent add` touches the
  contract and the roster and nothing else.
- **oikos's specific loosenings.** All seven were granted to two named
  agents after evidence. A new house starts with an empty table; that is
  the point of the table.
- **The `~/oikos` path confusion.** oikos's contract says `~/oikos` and the
  checkout is `~/Work/oikos`. Templates render the real path, once, at init.
- **The practice.** oikos's contract runs to 1,100 lines; the template holds
  the authority model, three guard rules and the house's own mechanics, and
  no worked examples. Until 2026-09-17 it also carried the house-rules block
  fold wrote and agora kept — sixteen bold headings from *Push back* to
  *Clean up before you leave* — as if it were part of the contract; that is
  now `templates/style/strict.md`, rendered as `notes/house-style.md` only by
  `house init --style strict`. A house writes its own notes as it earns them
  and wires each to the Read-first table.
- **Discord, Bluesky, mail, chat mirror.** Each is a channel oikos granted
  in the owner's turn. The template's Communication section says how such a
  grant is recorded, and grants none.

## Added, not inherited

- **The housekeeper.** oikos gave `knick` "housekeeping" as a first duty
  next to triage and an upstream voice, and the two pulled against each
  other: the housekeeper needed a GitHub identity to argue triage, and the
  identity was the thing the record then had to audit. agora had no
  housekeeper at all; the owner kept the record. house-framework ships the
  duty on its own, as an agent that carries no GitHub identity and no mail
  by design, so that the one agent whose job is trust in the record is
  never itself a voice the record has to account for. It is on every roster
  from `init` unless `--no-housekeeper`. On 2026-09-16 the owner fixed two
  more things about it: there is exactly one per house and its name is
  always `housekeeper`, and it is the house speaking rather than a resident
  of it — so its home is `~/agents/<house>/home` and an exported definition
  is named after the house. The first version had a `--housekeeper-name`
  flag, added only so two houses could share one `~/agents`; keying the
  home by house removed the reason for it.
- **Harness independence.** fold, oikos and agora all wrote Claude Code
  definitions into `~/.claude/agents/` as part of adding an agent, and the
  first house-framework did too. The owner's rule on 2026-09-16 is that a
  house does not depend on a runner: the roster carries the agent's kind,
  the home `AGENTS.md` is its brief, and a runner's file is a projection of
  those made by `house export <harness>`, kept under `templates/harness/`.
  The contract now says "the definitions a harness reads" where it used to
  say a path.
- **Presets.** Filed as the "oikos tier as a preset" item on 2026-09-16 and
  built on 2026-09-17: `house init --with notes,shimmer` declares each
  package with an exact shiv pin and the `[plugins] shiv` line, wires what
  the package needs, and rewrites the record where the package makes it
  false. The default is unchanged: no `--with`, one aqua tool. What the
  build changed from the item as filed: `agent-env` is **not** swapped for
  `shimmer as`, because `shimmer as` reads its token through `secrets` and
  the desktop keyring, and the owner ruled on 2026-09-17 (after oikos lost
  every agent credential to a shadowed keyring) that a house depends on
  neither; the shimmer preset wires `agent:list` instead, so shimmer reads
  the roster minus the housekeeper. `secrets` has no preset and will not
  get one. `notes` cannot be switched on by `init` — encryption needs the
  owner's key — so the preset declares, rewrites, and leaves `notes setup
  --gpg-key` as the owner's step, with `house doctor` failing until it has
  run. `chat`, `emails` (each needs the loosening row) and `tits` (which
  of `agent add` and `tits` owns `~/agents/<name>/home`) are still open.

## Open

- **A triage agent.** oikos has `knick`; agora decided the owner files.
  `agent add` makes a judge either way; whether a house wants one that ranks
  the queue is the owner's call and is not templated. It would be a judge,
  not the housekeeper: ranking needs an upstream voice and the housekeeper
  has none.
- **`house upgrade`.** When a template improves, reaching existing houses is
  by hand. A diff-and-propose task that files a backlog entry rather than
  editing the contract would fit the two-key rule.
- **A second harness.** `export claude-code` is the only exporter. The
  shape — kind to tool set, roster to one file per agent, the housekeeper's
  file named after the house — is meant to be copied for the next runner;
  the first copy will show what belongs in `lib/house.sh` and what stays
  per harness.

## Moved out of the house layer, 2026-09-17

house-framework#6 measured a fresh `house init` against its own claim to be
a starting point: 131 of the rendered contract's 246 non-blank lines were
byte-identical to agora's, the house named oikos, fold or Knick Knack Labs
ten times in four of its own files, and `doctor` called it healthy. The
invariants were not the problem; the voice and the defaults were. What
moved, and where to:

- **The self-description.** The contract's second paragraph explained the
  house by reference to house-framework, oikos and fold (agora's opening,
  one generation on). It is now a `house:decide` marker asking the owner
  what the house is. The README keeps one line, `Started from
  house-framework on <date>`, and the bootstrap commit names the framework
  and the style, if any. That is all the attribution a house carries.
- **The house-rules block.** fold's headings, agora's text, six oikos
  clauses condensed — none an invariant, all rendered as if they were. The
  three that protect the guard and the shared checkout stay in the
  contract, phrased without naming a runner: own your commits, prove the
  tree in the command that writes, stage by explicit path. The rest is
  `templates/style/strict.md`, a note the owner asks for with `--style`.
- **The lineage's answers where the owner's go.** The two backlog seeds
  were oikos's upgrade path; the mail domain `<house>.local` was the
  `OIKOS_EMAIL_DOMAIN` idea in a house with no mail; "Compared with oikos"
  made the absence list a comparison; `--owner` was parsed and rendered
  nowhere. Each is now either rendered (`--owner`, into "Who lives here")
  or a marker (the first backlog entries, the author domain, which absences
  the house cares about, how the owner merges, each agent's Stance). The
  author label is `<name>@<house>.invalid`: a reserved name that belongs to
  nobody, so the house claims nothing it does not own.
- **Runner and toolchain words.** "The Bash tool starts a fresh shell per
  call" is one runner's tool, stated in the contract, the guard and every
  home as a property of the world; it now reads "a runner may start a
  fresh shell for every command". `[[ABORT]]` is shimmer's CI-wake
  convention and lives only in the shimmer preset's Tooling bullet. The
  `bats` pin stays, for the reason under *Dropped* above, and is the only
  place a default house spells Knick Knack Labs.
- **A rule set declaring its own tier.** The money rules said "This line is
  Tier 3 for the whole house" from outside the tiers block, against the
  rule that Tier 3 is enumerated in one place. The claim is dropped; the
  line stays as a money rule. Putting the bullet inside Tier 3 by tool was
  the other route and is the owner's to take.

`doctor` now fails on every `house:decide` marker, leftover `{{KEY}}`,
unwritten Stance and lineage name, so a fresh house is not healthy until the
owner has made it theirs — which is the correct state for a starting point.
`examples/` is what `init` renders before that, regenerated by `mise run
examples --write` and checked by `mise run test`.
