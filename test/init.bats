load test_helper

@test "init scaffolds a standalone house with its own repo and a bootstrap commit" {
  run house init hearth --at "$BATS_TEST_TMPDIR/hearth"
  assert_success
  assert_output_contains "create: AGENTS.md"
  assert_output_contains "commit: bootstrap the household"

  h="$BATS_TEST_TMPDIR/hearth"
  for f in AGENTS.md README.md mise.toml roster.tsv .gitignore hooks/agent-identity \
           .mise/tasks/welcome .mise/tasks/test .mise/tasks/agent-env .mise/tasks/install-hooks \
           notes/work-queue.md notes/household-backlog.md \
           test/agent_env.bats test/agent_identity.bats test/roster.bats; do
    [ -f "$h/$f" ]
  done
  [ -x "$h/hooks/agent-identity" ]
  [ -x "$h/.mise/tasks/welcome" ]
  [ -d "$h/.git" ]
  [ "$(git -C "$h" log --oneline | wc -l)" -eq 1 ]
  [ -z "$(git -C "$h" status --porcelain)" ]
}

@test "init renders the house name into the contract, the guard and the env" {
  house init hearth --at "$BATS_TEST_TMPDIR/hearth"
  h="$BATS_TEST_TMPDIR/hearth"
  assert_file_contains "$h/AGENTS.md" "# hearth"
  assert_file_contains "$h/AGENTS.md" "HEARTH_OWNER_COMMIT=1"
  assert_file_contains "$h/hooks/agent-identity" 'HEARTH_OWNER_COMMIT'
  assert_file_contains "$h/mise.toml" 'HOUSE_NAME = "hearth"'
  assert_file_contains "$h/mise.toml" 'WORK_DIR = "{{ config_root }}"'
  ! grep -q '{{HOUSE' "$h/AGENTS.md"
  ! grep -rq '{{HOUSE' "$h/.mise" "$h/hooks" "$h/test" "$h/notes"
}

@test "init --embedded places the house inside a project repo without a repo of its own" {
  project="$(make_project)"
  run house init hall --at "$project/hall" --embedded
  assert_success
  assert_output_contains "next: review the new files"
  [ ! -d "$project/hall/.git" ]
  assert_file_contains "$project/hall/mise.toml" 'WORK_DIR = "{{ config_root }}/.."'
  assert_file_contains "$project/hall/mise.toml" 'HOUSE_PROJECT = "project"'
  assert_file_contains "$project/hall/AGENTS.md" "lives **inside** the project"
  [ -n "$(git -C "$project" status --porcelain -- hall)" ]
}

@test "init --embedded refuses a parent that is not a git repository" {
  run house init hall --at "$BATS_TEST_TMPDIR/loose/hall" --embedded
  assert_failure
  assert_output_contains "--embedded needs the parent"
}

@test "init --project names what the house works on" {
  house init hearth --at "$BATS_TEST_TMPDIR/hearth" --project "Evento Livre"
  assert_file_contains "$BATS_TEST_TMPDIR/hearth/AGENTS.md" "agents of **Evento Livre**"
  assert_file_contains "$BATS_TEST_TMPDIR/hearth/mise.toml" 'HOUSE_PROJECT = "Evento Livre"'
}

@test "init keeps existing files and reports them" {
  h="$BATS_TEST_TMPDIR/hearth"
  mkdir -p "$h"
  printf 'mine\n' > "$h/README.md"
  run house init hearth --at "$h" --no-commit
  assert_success
  assert_output_contains "keep: README.md"
  [ "$(cat "$h/README.md")" = "mine" ]
}

@test "init rejects a name that is not lowercase-kebab" {
  run house init Hearth --at "$BATS_TEST_TMPDIR/x"
  assert_failure
  run house init "my house" --at "$BATS_TEST_TMPDIR/y"
  assert_failure
}

@test "a fresh house passes its own checks" {
  house init hearth --at "$BATS_TEST_TMPDIR/hearth"
  run in_house "$BATS_TEST_TMPDIR/hearth" test
  assert_success
  assert_output_contains "== bats =="
  assert_output_contains "== welcome smoke =="
}

@test "a fresh house's welcome reports an empty roster and a missing guard" {
  house init hearth --at "$BATS_TEST_TMPDIR/hearth" --no-housekeeper
  run env -u GIT_AUTHOR_NAME bash -c 'in_house "$@"' _ "$BATS_TEST_TMPDIR/hearth" welcome
  assert_success
  assert_output_contains "not activated"
  assert_output_contains "nobody yet"
  assert_output_contains "pre-commit guard: missing"
  assert_output_contains "nothing queued"
}

@test "install-hooks wires the guard into the work tree and the guard refuses the owner" {
  house init hearth --at "$BATS_TEST_TMPDIR/hearth"
  h="$BATS_TEST_TMPDIR/hearth"
  run in_house "$h" install-hooks
  assert_success
  [ -x "$h/.git/hooks/pre-commit" ]

  printf 'x\n' > "$h/scratch.md"
  git -C "$h" add scratch.md
  run env GIT_CONFIG_GLOBAL=/dev/null git -C "$h" -c commit.gpgsign=false commit -q -m "as the owner"
  assert_failure
  assert_output_contains "refusing this commit"

  run env GIT_CONFIG_GLOBAL=/dev/null HEARTH_OWNER_COMMIT=1 git -C "$h" -c commit.gpgsign=false commit -q -m "as the owner, deliberately"
  assert_success
}

@test "init ships a housekeeper by default, with no GitHub identity and no mail" {
  house init hearth --at "$BATS_TEST_TMPDIR/hearth"
  h="$BATS_TEST_TMPDIR/hearth"
  grep -q $'^housekeeper\thousekeeping\t$' "$h/roster.tsv"
  assert_file_contains "$h/AGENTS.md" "- **housekeeper** — housekeeping. Owns no directory."
  assert_file_contains "$h/AGENTS.md" "The exception is **housekeeper**, the housekeeper"
  assert_file_contains "$h/AGENTS.md" "The housekeeper is"
  assert_file_contains "$h/notes/household-backlog.md" "The housekeeper is not in this entry"
  assert_file_contains "$h/notes/housekeeper.md" "No GitHub account, no signing key, no mail — by design"
  assert_file_contains "$AGENTS_ROOT/housekeeper/home/AGENTS.md" "no GitHub account, no signing key, and no mail, permanently"
  assert_file_contains "$DEFINITIONS_DIR/housekeeper.md" "name: housekeeper"
  assert_file_contains "$DEFINITIONS_DIR/housekeeper.md" "no GitHub account, no signing key and"
  assert_file_contains "$DEFINITIONS_DIR/housekeeper.md" "tools: Read, Grep, Glob, Bash, Edit, Write"
  ! grep -rq '{{' "$h/notes/housekeeper.md" "$AGENTS_ROOT/housekeeper/home" "$DEFINITIONS_DIR/housekeeper.md"
  [ -z "$(git -C "$h" status --porcelain)" ]
  run in_house "$h" test
  assert_success
}

@test "init --no-housekeeper leaves the roster empty and says so in the contract" {
  house init hearth --at "$BATS_TEST_TMPDIR/hearth" --no-housekeeper
  h="$BATS_TEST_TMPDIR/hearth"
  [ "$(awk -F '\t' '!/^#/ && NF' "$h/roster.tsv" | wc -l)" -eq 0 ]
  assert_file_contains "$h/AGENTS.md" "This house has no housekeeper"
  [ ! -e "$DEFINITIONS_DIR/housekeeper.md" ]
}

@test "init --housekeeper-name names it, and a taken name is refused" {
  house init hearth --at "$BATS_TEST_TMPDIR/hearth" --housekeeper-name hestia
  grep -q '^hestia' "$BATS_TEST_TMPDIR/hearth/roster.tsv"
  [ -f "$DEFINITIONS_DIR/hestia.md" ]
  run house init hall --at "$BATS_TEST_TMPDIR/hall" --housekeeper-name hestia
  assert_failure
  assert_output_contains "already exists"
  assert_output_contains "--housekeeper-name"
}

@test "the housekeeper's guard and env work like any agent's" {
  house init hearth --at "$BATS_TEST_TMPDIR/hearth"
  h="$BATS_TEST_TMPDIR/hearth"
  run env -u HEARTH_OWNER_COMMIT GIT_AUTHOR_NAME=housekeeper "$h/hooks/agent-identity"
  assert_success
  run in_house "$h" agent-env housekeeper
  assert_success
  assert_output_contains "export GIT_AUTHOR_NAME=housekeeper"
}
