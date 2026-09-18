# house

A tool repo, not a household. There is no roster here, no queue and no
`notes/`; a house's notes come only from `scaffold/`, and the households
this shape was distilled from are named in `lib/lineage-names` and in git
history, nowhere else. This file is the contract for this repository, for
whoever's agent works on it — yours, under any harness or none, with no
house behind it. It says what the repo must preserve and what a change
needs; [`CONTRIBUTING.md`](CONTRIBUTING.md) has the mechanics. An agent
that does belong to a house is still governed by that house's contract;
this one governs the repo.

## What this repo must preserve

`scaffold/house/` is the house every owner gets, byte for byte but for the
facts, and `scaffold/house/AGENTS.md` is the contract every new house
starts from. The framework asserts the shape and the opinions; the owner
supplies facts and, later, dated widenings. A change to the scaffold
changes the house every future owner gets, so the same discipline applies
here as in a live house:

- **The tiers, the two-key rule and the loosenings table stay whole and in
  one place** in the scaffold's contract. Do not split them, summarise them
  elsewhere, or add a second copy in a home or a definition.
- **The scaffold only narrows by default.** A widening — an agent that may
  merge, push `main`, or act on relayed approval — is never the starting
  point. A house grants it as a dated row after it exists.
- **The three markers** (`house:roster`, `house:rules`, `house:read-first`)
  are load-bearing: `agent add` and `rules add` insert at them and `doctor`
  checks for them. Rename one and every existing house fails `doctor`.
- **A fresh house is complete.** The framework asserts; the owner supplies
  facts and grants widenings. `init` asks nothing: no `house:decide`
  marker exists in `scaffold/` or in a rendered house, no flag selects a
  file, every house gets its housekeeper, and
  `house init x && house doctor --house x` exits 0. Where only the owner
  can answer — the owner's name — `init` takes the fact as an argument and
  fails without it. What the framework used to ask, it now states: what a
  house is, how the owner merges, the house style, the author domain, what
  is not there yet, each agent's Stance. `doctor` still fails a leftover
  `{{KEY}}` and every name a `house` line of `lib/lineage-names` lists
  (`KnickKnackLabs` outside `mise.toml` too), because those are the
  framework's and never the owner's text.
- **Substitution is facts only, and the list is closed.** A key in a
  scaffold file names a fact the house or the agent has; it never selects a
  passage. The house facts are `{{HOUSE_NAME}}`, `{{HOUSE_UPPER}}`,
  `{{HOUSE_PATH}}`, `{{WORK_PATH}}`, `{{WORK_DIR_EXPR}}`, `{{PROJECT}}`,
  `{{CREATED}}`, `{{FRAMEWORK_VERSION}}` and `{{OWNER}}`;
  `{{AUTHOR_DOMAIN}}` is derived from the name; `{{PLACEMENT}}` is the one
  two-way structural fact, embedded or standalone. The agent facts are
  `{{AGENT}}`, `{{ROLE}}`, `{{OWNS}}`, `{{CHARGE}}`, `{{WORKSPACE_PATH}}`
  and `{{HOME_PATH}}`.
  `test/own_house.bats` greps `scaffold/` and fails on any key outside
  this list, and on any key in this list that this paragraph does not
  name. A key that would select text is a template, and templates are
  refused.
- **No presets, no menus.** The asserted toolchain is git, bash, `mise` and
  the one `bats` pin. A house that wants a package adds the pin, the
  wiring and the dated loosening row in its own turn; the contract's
  Tooling and Communication sections say how.
- **This is a tool for strangers.** house is public and meant for
  people who have never heard of the households it grew out of. Personal
  names, lineage names and the name of the runner the lineage ran under
  appear in `lib/lineage-names` alone: `doctor` reads its `house` lines to
  reject those names in a generated house, and `test/agent_add.bats` reads
  its `runner` line to assert a house never carries that one. Usage
  examples, help text, the scaffold and the tests use generic names
  (`example`, `builder`, `Your Name`) and paths that mean the same on
  every machine. No harness is named anywhere else. The repo-wide test in
  `test/own_house.bats` greps every file but that one for every name on
  the list and fails on any other mention; the one personal string it
  allows is the address of this repository, which a house's README links.
- **The housekeeper stays voiceless, singular and named.** Its scaffold
  (`scaffold/agent/housekeeper/`) states that it has no GitHub identity and
  no mail by design, and the contract's Tooling clause excludes it from any
  identity entry the owner files. Its name is the constant `HOUSEKEEPER`
  in `lib/house.sh`; its home is keyed by the house name, and a runner's
  definition for it, where one exists, is named after the house. Every
  house has it from `init`. Do
  not add a rename flag, a `--github` or `--mail` path, a way to skip it,
  or a way to have two; a house that wants a speaking agent adds a judge.
- **The house is harness-agnostic.** `init`, `agent add` and `doctor` read
  and write only the house, `~/agents/<name>/home` and the roster. Nothing
  here writes a runner's files: what a runner needs is `roster.tsv`, each
  home's `AGENTS.md` and the rule that the housekeeper's file is named
  after the house, and its definition is the owner's to write outside the
  house. Do not add an exporter, and do not let a harness path, tool name
  or settings file into the contract, the notes, the homes or the library.
- **Generated files are never overwritten.** `install_tree` and `agent add`
  keep what exists and say so. A change to the scaffold reaches an existing
  house only by hand, in that house's own turn.

## Working here

```bash
mise run test        # bats, and a syntax pass over the scaffold's executables
git diff --check
```

- Scaffold files carry `{{KEY}}` — uppercase, no spaces, one of the facts
  listed above and nothing else. mise's own `{{ config_root }}` and
  `{{ env.X }}` have spaces and pass through untouched; keep it that way.
- The scaffold's executables (`hooks/`, `.mise/tasks/`) must pass
  `bash -n`; the test task runs it.
- `rules/` is the last menu in the tree, moved out of `templates/` whole
  and awaiting its own removal
  ([#15](https://github.com/olavostauros/house/issues/15)). Do not add to
  it.
- Comments carry constraints, not narrative. No decorative separators.
- Commit messages: conventional, no footers, no tool attribution.
- When the scaffold changes and you know which house of the lineage its
  practice came from, say so in the commit; if you do not, say it is new.
  Nobody is expected to know.
