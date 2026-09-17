# house-framework

**The starting point of a house of agents.**

A *house* is a directory where a roster of agents wake, read their rules,
take work from a queue, and return. `house-framework` scaffolds one, adds
agents to it, drops in domain rule sets, and checks it against the shape
every house shares. The command is `house`.

A house does not depend on any agent harness. Everything it generates is
markdown, bash, git and `mise`; a runner such as Claude Code gets its agent
definitions from a separate `house export <harness>` step that reads the
roster and can be re-run or ignored.

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

# The same, on encrypted notes and shimmer (exact shiv pins, opt-in)
house init oikos --at ~/Work/oikos --with notes,shimmer

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

# Only if the agents run under Claude Code
house export claude-code
```

## What `init` writes

| Path | What it is |
|---|---|
| `AGENTS.md` | the contract: house rules, a slot for domain rule sets, the tiers, the loosenings table, the two-key rule, the Read-first table |
| `roster.tsv` | who counts as an agent, with role, owned directory and kind — read by the guard, `agent-env`, `welcome`, `doctor` and every exporter |
| `notes/work-queue.md` | the owner files entries here, each addressed to one agent |
| `notes/household-backlog.md` | Tier 2 proposals; seeded with the two upgrades every house eventually wants |
| `hooks/agent-identity` | pre-commit guard: refuses an author not on the roster unless `<HOUSE>_OWNER_COMMIT=1` |
| `.mise/tasks/{welcome,test,agent-env,install-hooks}` | the task surface |
| `test/*.bats` | the house's own checks, roster-driven so they stay true as agents join |
| `mise.toml`, `README.md`, `.gitignore` | the rest |
| `--with notes,shimmer` | opt-in: each named package as an exact `shiv:` pin plus `[plugins] shiv`, its wiring (`agent:list` for shimmer), its bats file, and the contract, README and backlog rewritten where the package makes them false; without the flag nothing changes |

A standalone house gets its own repo and a bootstrap commit. An embedded
house is a directory of the project repo; you commit it as the owner.

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
Its note and its home say so, and the backlog entry that gives the other
agents identities names it as excluded. It reads GitHub through the owner's
login and writes nothing there; it pushes nothing. The record can be trusted
because the one agent whose job is the record has no voice outside the house.

## What `agent add` writes

- a row on `roster.tsv`: name, role, owned directory, kind
- `notes/<name>.md`, the household-visible identity
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
matching `.mise/tasks/export/<name>` task; the first is `claude-code`,
which writes `~/.claude/agents/<name>.md` (`HOUSE_DEFINITIONS_DIR` or
`--to` override the directory).

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
