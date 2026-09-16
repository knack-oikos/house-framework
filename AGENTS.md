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
- **The housekeeper stays voiceless.** Its three templates
  (`note.housekeeper`, `home/AGENTS.housekeeper`, `definition.housekeeper`)
  each state that it has no GitHub identity and no mail by design, and the
  backlog template excludes it from the identity entry. Do not add a
  `--github` or `--mail` path for it; a house that wants a speaking agent
  adds a judge.
- **Generated files are never overwritten.** `install_tree` and `agent add`
  keep what exists and say so. A change to a template reaches an existing
  house only by hand, in that house's own turn.

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
