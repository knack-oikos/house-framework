load test_helper

listed_names() {
  awk -v kind="${1:-}" 'kind == "" || $1 == kind { print $2 }' "$REPO_DIR/lib/lineage-names" | paste -sd '|'
}

HOUSE_KEYS="HOUSE_NAME HOUSE_UPPER HOUSE_PATH WORK_PATH WORK_DIR_EXPR PROJECT CREATED FRAMEWORK_VERSION OWNER AUTHOR_DOMAIN PLACEMENT"
AGENT_KEYS="AGENT ROLE OWNS CHARGE WORKSPACE_PATH HOME_PATH"

setup() {
  house_setup
  LINEAGE="$(listed_names)|KnickKnackLabs|Knick Knack Labs|Bash tool|\[\[ABORT\]\]"
}

@test "the framework ships no household or personal name outside lib/lineage-names" {
  run bash -c "grep -rniwE '$(listed_names)' --exclude-dir=.git --exclude=lineage-names '$REPO_DIR' | grep -vE 'olavostauros/house([^a-z0-9-]|$)'"
  [ -z "$output" ]
  [ "$(awk '$1 == "house"' "$REPO_DIR/lib/lineage-names" | wc -l)" -ge 1 ]
}

@test "the framework is a bootstrap, not a house: no notes/, no lineage file" {
  [ ! -e "$REPO_DIR/notes" ]
  [ ! -e "$REPO_DIR/LINEAGE.md" ]
  run find "$REPO_DIR" -path "$REPO_DIR/.git" -prune -o -iname 'lineage*' -print
  [ "$output" = "$REPO_DIR/lib/lineage-names" ]
}

@test "the framework has a scaffold, not templates: no menu, no .tmpl, and nothing that asks the owner" {
  [ ! -e "$REPO_DIR/templates" ]
  [ ! -e "$REPO_DIR/examples" ]
  [ -d "$REPO_DIR/scaffold/house" ]
  [ -d "$REPO_DIR/scaffold/agent" ]
  run find "$REPO_DIR/scaffold" -name '*.tmpl'
  [ -z "$output" ]
  run grep -rl 'house:decide' "$REPO_DIR/scaffold" "$REPO_DIR/lib" "$REPO_DIR/.mise"
  [ -z "$output" ]
  run grep -rlE 'usage_(style|with|no_housekeeper|kind|no_home)\b' "$REPO_DIR/lib" "$REPO_DIR/.mise"
  [ -z "$output" ]
}

@test "every key in the scaffold names a fact, and AGENTS.md enumerates each one" {
  run bash -c "grep -rohE '\{\{[A-Z_]+\}\}' '$REPO_DIR/scaffold' | sort -u | tr -d '{}'"
  [ -n "$output" ]
  for key in $output; do
    case " $HOUSE_KEYS $AGENT_KEYS " in
      *" $key "*) ;;
      *) printf 'not a fact key: {{%s}}\n' "$key" >&2; return 1 ;;
    esac
  done
  for key in $HOUSE_KEYS $AGENT_KEYS; do
    grep -qF "\`{{$key}}\`" "$REPO_DIR/AGENTS.md"
  done
}

@test "a fresh house names no lineage, no runner and no mail domain, and keeps one line of attribution" {
  h="$BATS_TEST_TMPDIR/hearth"
  house init hearth --at "$h"
  house agent add vulcan --house "$h" --role backend --owns server/ >/dev/null
  house agent add argus --house "$h" --role review >/dev/null
  house rules add money --house "$h" --binds vulcan >/dev/null
  run bash -c "grep -rniwE '$LINEAGE' --exclude-dir=.git --exclude=mise.toml '$h' '$AGENTS_ROOT' | grep -vE 'olavostauros/house([^a-z0-9-]|$)'"
  [ -z "$output" ]
  run grep -niwE "$LINEAGE" "$h/mise.toml"
  [ "$output" = $'14:"aqua:KnickKnackLabs/bats-core" = "1.14.0-kkl.3"\n17:registries = ["https://github.com/KnickKnackLabs/bats-core"]' ]
  run grep -rnE '@[^[:space:]`]*\.local' --exclude-dir=.git "$h" "$AGENTS_ROOT"
  [ "$status" -eq 1 ]
  run grep -rn 'Tier 3 for the whole house' "$h/AGENTS.md"
  [ "$status" -eq 1 ]
  [ "$(grep -rho 'github.com/olavostauros/house' --exclude-dir=.git "$h" "$AGENTS_ROOT" | wc -l)" -eq 1 ]
  assert_file_contains "$h/README.md" "Started from [house](https://github.com/olavostauros/house)"
  assert_file_contains "$h/README.md" "on $(date +%Y-%m-%d), at $(house version)."
  [ "$(git -C "$h" log -1 --format=%s)" = "hearth: bootstrap the household from house" ]
}

@test "the fresh contract holds the authority sections and three guard rules, asserts the merge rule, and wires the house style" {
  h="$BATS_TEST_TMPDIR/hearth"
  house init hearth --at "$h"
  run sed -nE 's/^\*\*([^*]+)(\*\*.*)?$/\1/p' "$h/AGENTS.md"
  expected="\`$h\` is a single shared checkout.
Own your commits.
Prove the tree in the same command that writes.
Stage by explicit path.
Agents may narrow their own constraints at any time. Only the owner widens
Notes are plaintext here."
  [ "$output" = "$expected" ]
  for line in "### The tiers — canonical list" "#### Tier 1 — free to change" "#### Tier 2 — propose, do not apply" \
              "#### Tier 3 — never, by any agent" "#### The two-key rule" "### The loosenings — canonical list" \
              "| # | Date | Grant | Applies to |" "### Read first" \
              "<!-- house:roster -->" "<!-- house:rules -->" "<!-- house:read-first -->"; do
    grep -qxF -- "$line" "$h/AGENTS.md"
  done
  assert_file_contains "$h/AGENTS.md" "None granted yet."
  assert_file_contains "$h/AGENTS.md" "with a merge commit, never a squash or a rebase"
  assert_file_contains "$h/AGENTS.md" "[[house-style]], wired to Read-first"
  assert_file_contains "$h/AGENTS.md" '| commit, review, open a PR, or end a session | [`notes/house-style.md`](notes/house-style.md) |'
  ! grep -q "Merge, don't squash" "$h/AGENTS.md"
  ! grep -q "Push back when something smells off" "$h/AGENTS.md"
  assert_file_contains "$h/notes/house-style.md" "title: house-style"
  assert_file_contains "$h/notes/house-style.md" "**Merge, don't squash.**"
  assert_file_contains "$h/notes/house-style.md" "**Push back when something smells off.**"
  assert_file_says "$h/notes/house-style.md" "The framework wrote it and the owner changes it, in the owner's own turn"
  ! grep -qiwE "$LINEAGE" "$h/notes/house-style.md"
  ! grep -q '{{' "$h/notes/house-style.md"
}

@test "init renders --owner into the contract, falls back to git user.name, and fails when nobody is named" {
  h="$BATS_TEST_TMPDIR/hearth"
  house init hearth --at "$h" --owner "Ada"
  assert_file_contains "$h/AGENTS.md" "The owner is **Ada**: the one human here, who files the queue, merges,"
  house init hall --at "$BATS_TEST_TMPDIR/hall"
  assert_file_contains "$BATS_TEST_TMPDIR/hall/AGENTS.md" "The owner is **house test**: the one human here"
  run env GIT_CONFIG_COUNT=0 bash -c 'house "$@"' _ init keep --at "$BATS_TEST_TMPDIR/keep"
  assert_failure
  assert_output_contains "the owner has no name: pass --owner '<name>', or set git config user.name"
  [ ! -e "$BATS_TEST_TMPDIR/keep/AGENTS.md" ]
  [ ! -e "$AGENTS_ROOT/keep" ]
}

@test "a fresh house, with a builder and a judge, asks the owner nothing, carries no key, and is healthy" {
  h="$BATS_TEST_TMPDIR/hearth"
  house init hearth --at "$h"
  house agent add vulcan --house "$h" --role backend --owns server/ >/dev/null
  house agent add argus --house "$h" --role review >/dev/null
  run grep -rl 'house:decide' --exclude-dir=.git "$h" "$AGENTS_ROOT"
  [ -z "$output" ]
  run grep -rlE '\{\{[A-Z_]+\}\}' --exclude-dir=.git "$h" "$AGENTS_ROOT"
  [ -z "$output" ]
  run grep -rl 'The owner writes this section' --exclude-dir=.git "$h" "$AGENTS_ROOT"
  [ -z "$output" ]
  for agent in housekeeper vulcan argus; do
    assert_file_contains "$h/notes/$agent.md" "## Stance"
    assert_file_says "$h/notes/$agent.md" "Narrowing this stance is $agent's; widening it is the owner's."
  done
  run house doctor --house "$h"
  assert_success
  assert_output_contains "doctor: healthy"
  run in_house "$h" test
  assert_success
}
