---
title: lineage
tags: [design, history]
created: 2026-09-16
updated: 2026-09-16
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
| oikos | the git rules: cite by SHA, merge don't squash, small never stacked, prove the branch in the same command, unpushed is invisible, a dirty tree may not be yours | each has a dated near-miss behind it |
| agora | the embedded placement, directory ownership, the owner files the queue, no agent merges, the seam rule (interface one owns, call site another owns) | the smallest form that still separates authority from work |
| agora | `agent-env` instead of `shimmer as`, plaintext notes, the owner as transport | a house should wake on day one with `git`, `mise` and `bats` only |
| agora | the four rule sets | they are what turned a style guide into a contract |
| agora | the "what is deliberately not here yet" list | so the missing pieces read as choices, not gaps |

## Dropped, and why

- **The KKL toolchain as a requirement.** fold and oikos declare thirteen
  shiv packages; a fresh house declares one aqua tool. Each package is an
  upgrade the owner adds when a reason exists. The backlog template seeds
  the two that always come first — encryption and per-agent identity.
- **Hardcoded rosters.** agora repeats its four names in the hook, in
  `agent-env`, in `welcome` and in every test. house-framework puts them in
  `roster.tsv` and has everything read it, so `agent add` touches the
  contract and the roster and nothing else.
- **oikos's specific loosenings.** All seven were granted to two named
  agents after evidence. A new house starts with an empty table; that is
  the point of the table.
- **The `~/oikos` path confusion.** oikos's contract says `~/oikos` and the
  checkout is `~/Work/oikos`. Templates render the real path, once, at init.
- **The practice.** oikos's contract runs to 1,100 lines; the template is
  about a third of that and holds rules, not worked examples. A house writes
  its own notes as it earns them and wires each to the Read-first table.
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

## Open

- **A triage agent.** oikos has `knick`; agora decided the owner files.
  `agent add` makes a judge either way; whether a house wants one that ranks
  the queue is the owner's call and is not templated. It would be a judge,
  not the housekeeper: ranking needs an upstream voice and the housekeeper
  has none.
- **`house upgrade`.** When a template improves, reaching existing houses is
  by hand. A diff-and-propose task that files a backlog entry rather than
  editing the contract would fit the two-key rule.
- **The oikos tier as a preset.** `house init --with notes,shimmer` could
  declare the packages and swap `agent-env` for `shimmer as`. Not built
  until a second house wants it.
- **A second harness.** `export claude-code` is the only exporter. The
  shape — kind to tool set, roster to one file per agent, the housekeeper's
  file named after the house — is meant to be copied for the next runner;
  the first copy will show what belongs in `lib/house.sh` and what stays
  per harness.
