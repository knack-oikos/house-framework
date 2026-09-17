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
- **A preset declares, wires, and widens only in the record.** `house init
  --with <pkg>` renders the exact shiv pin and the `[plugins] shiv` line,
  adds or swaps the task the package needs, and rewrites the passages of
  the contract, the README and the backlog that the package makes false.
  Nothing else. Every placeholder a preset fills is empty by default, so
  `house init x` with no `--with` renders byte for byte what it did before
  presets existed. A channel a package opens (chat, mail) is a dated
  loosening row the preset writes under the owner's name, never a default,
  and never one that names the housekeeper. No preset may make identity,
  tokens or signing depend on a desktop keyring (`secrets`, libsecret,
  gnome-keyring): `shimmer as` does, so the shimmer preset does not wire it.
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
- Executable templates (`hooks/`, `.mise/tasks/`, the `welcome.sh`
  fragments) must pass `bash -n`; the test task runs it.
- A preset is a directory under `templates/preset/<pkg>/`: `pin` (the exact
  `"shiv:<pkg>" = "x.y.z"` line), `tooling.md` (its bullet in the contract),
  `welcome.sh` (its lines under `== packages ==`), optional `next` (what
  `init` prints for the owner) and an optional `house/` tree installed with
  the same keep-what-exists rule as `templates/house/`. Its `doctor` check
  lives in `.mise/tasks/doctor`, keyed by package name.
- Comments carry constraints, not narrative. No decorative separators.
- Commit messages: conventional, no footers, no tool attribution.
- When a template changes, say in the commit which of the three houses'
  practice it came from (fold, oikos, agora) or that it is new.
