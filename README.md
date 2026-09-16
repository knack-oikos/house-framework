# house-framework

**The starting point of a house of agents.**

A *house* is a directory where a roster of agents wake, read their rules,
take work from a queue, and return. `house-framework` scaffolds one, adds
agents to it, drops in domain rule sets, and checks it against the shape
every house shares. The command is `house`.

It distils three generations of the same idea:

- [ricon-family/fold](https://github.com/ricon-family/fold) — the original
  home base, built on the
  [Knick Knack Labs](https://github.com/KnickKnackLabs) toolchain: `shiv`,
  `shimmer`, `notes`, `chat`, `emails`, `sessions`.
- [olavostauros/oikos](https://github.com/olavostauros/oikos) — fold forked
  for one household: the tiers, the loosenings table, the two-key rule, the
  refusal of relayed approval, encrypted notes, a work queue.
- `agora` (in `olavostauros/ticket`) — oikos stripped to what a house needs
  on day one: a contract, a roster, a queue, a commit guard, plaintext
  notes, the owner's login as transport, and rule sets for money, identity,
  data and review.

Every house starts at the agora tier. Each oikos capability — encryption,
per-agent GitHub identity, mail, chat, CI wakes — is a backlog entry the
owner switches on, and a dated widening in the contract when they do. See
[`notes/lineage.md`](notes/lineage.md) for what was kept, dropped, and why.

## Install

```bash
gh repo clone olavostauros/house-framework ~/Work/house-framework
cd ~/Work/house-framework && mise trust && mise install
```

Run it as `mise run <task>` from this directory, or register it as a
[shiv](https://github.com/KnickKnackLabs/shiv) package so `house` resolves
from anywhere:

```bash
shiv install house ~/Work/house-framework
```

## Quick start

```bash
# A house inside the project it works on
house init agora --at ~/Work/ticket/agora --embedded

# A house that is a repo of its own and works on other repos
house init oikos --at ~/Work/oikos

cd ~/Work/ticket/agora
house agent add caesar --role payments --owns payments/ \
  --charge 'Takes money for tickets, refunds it, reconciles it, reports on it.'
house agent add argus --role 'review and security' \
  --charge 'Reads every pull request into main before the owner merges it.'
house rules add money --binds caesar
house rules add review --binds argus

mise run install-hooks
mise run welcome
house doctor
```

## What `init` writes

| Path | What it is |
|---|---|
| `AGENTS.md` | the contract: house rules, a slot for domain rule sets, the tiers, the loosenings table, the two-key rule, the Read-first table |
| `roster.tsv` | who counts as an agent — read by the guard, `agent-env` and `welcome` |
| `notes/work-queue.md` | the owner files entries here, each addressed to one agent |
| `notes/household-backlog.md` | Tier 2 proposals; seeded with the two upgrades every house eventually wants |
| `hooks/agent-identity` | pre-commit guard: refuses an author not on the roster unless `<HOUSE>_OWNER_COMMIT=1` |
| `.mise/tasks/{welcome,test,agent-env,install-hooks}` | the task surface |
| `test/*.bats` | the house's own checks, roster-driven so they stay true as agents join |
| `mise.toml`, `README.md`, `.gitignore` | the rest |

A standalone house gets its own repo and a bootstrap commit. An embedded
house is a directory of the project repo; you commit it as the owner.

## The housekeeper

Every house ships one. `init` adds an agent named `housekeeper` (rename it
with `--housekeeper-name`, skip it with `--no-housekeeper`, add it later with
`house agent add <name> --kind housekeeper`). Its work is standing and needs
no filing: it measures the queue, the backlog, the notes, the roster and the
branches against what is on disk, fixes verified-false facts in `notes/` on
a local branch, files everything else as a backlog proposal, and reports to
the owner in the session.

It carries **no GitHub account, no signing key and no mail, permanently.**
Its note, its home and its definition all say so, and the backlog entry that
gives the other agents identities names it as excluded. It reads GitHub
through the owner's login and writes nothing there; it pushes nothing. The
record can be trusted because the one agent whose job is the record has no
voice outside the house.

## What `agent add` writes

- a row on `roster.tsv`
- `notes/<name>.md`, the household-visible identity
- a bullet under "Who lives here" and a row in the Read-first table
- `~/agents/<name>/home/` with `AGENTS.md`, `mise.toml`, `SCRATCHPAD.md`, as
  a local git repo
- `~/.claude/agents/<name>.md`, the Claude Code agent definition

Three kinds. `--owns <dir>/` makes a **builder**: takes queue entries, works
on `<name>/<topic>` branches under its directory, opens PRs, gets `Edit` and
`Write`. Without `--owns` it is a **judge**: owns nothing, answers in the
written record, gets `WebFetch` and `WebSearch` instead. `--kind
housekeeper` makes the one above. Whatever the kind, the owner merges and
the owner files the queue.

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
- **Homes and definitions are the agent's boundary**, not the house's:
  `agent add` creates them once and never overwrites them.
- **The housekeeper has no outward identity**, and no upgrade path gives it
  one.

## Development

```bash
mise trust
mise install
mise run test
git diff --check
```

The tests scaffold houses into temporary directories with `HOUSE_AGENTS_ROOT`
and `HOUSE_DEFINITIONS_DIR` pointed away from your real `~/agents` and
`~/.claude/agents`. Nothing under your home is touched.
