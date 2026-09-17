# house-framework

A tool repo, not a household. There is no roster here and no queue; an agent
working on this repo is working *for* whichever house asked for the change,
under that house's contract.

## What this repo must preserve

`templates/house/AGENTS.md.tmpl` is the contract every new house starts
from. Changes to it change what agents in future houses may do, so the same
discipline applies here as in a live house:

- **The tiers, the two-key rule and the loosenings table stay whole and in
  one place** in the template. Do not split them, summarise them elsewhere,
  or add a second copy in a home or definition template.
- **The template only narrows by default.** A widening — an agent that may
  merge, push `main`, or act on relayed approval — is never the starting
  point. A house grants it as a dated row after it exists.
- **The three markers** (`house:roster`, `house:rules`, `house:read-first`)
  are load-bearing: `agent add` and `rules add` insert at them and `doctor`
  checks for them. Rename one and every existing house fails `doctor`.
- **The housekeeper stays voiceless, singular and named.** Its templates
  (`agent/note.housekeeper`, `agent/home/AGENTS.housekeeper`, and each
  harness's `definition.housekeeper`) each state that it has no GitHub
  identity and no mail by design, and the backlog template excludes it from
  the identity entry. Its name is the constant `HOUSEKEEPER` in
  `lib/house.sh`; its home is keyed by the house name, and an exported
  definition is named after the house. Do not add a rename flag, a
  `--github` or `--mail` path, or a way to have two; a house that wants a
  speaking agent adds a judge.
- **The house is harness-agnostic.** `init`, `agent add` and `doctor` read
  and write only the house, `~/agents/<name>/home` and the roster. Anything
  a runner needs lives under `templates/harness/<name>/` and is written only
  by `.mise/tasks/export/<name>`. Do not let a harness path, tool name or
  settings file back into the contract, the notes, the homes or the library.
- **Generated files are never overwritten.** `install_tree`, `agent add` and
  every exporter keep what exists and say so (`export` takes `--force`). A
  change to a template reaches an existing house only by hand, in that
  house's own turn.

## Working here

```bash
mise run test        # bats + a syntax pass over the executable templates
git diff --check
```

- Templates render with `{{KEY}}` — uppercase, no spaces. mise's own
  `{{ config_root }}` and `{{ env.X }}` have spaces and pass through
  untouched; keep it that way.
- Executable templates (`hooks/`, `.mise/tasks/`) must pass `bash -n`; the
  test task runs it.
- Comments carry constraints, not narrative. No decorative separators.
- Commit messages: conventional, no footers, no tool attribution.
- When a template changes, say in the commit which of the three houses'
  practice it came from (fold, oikos, agora) or that it is new.
