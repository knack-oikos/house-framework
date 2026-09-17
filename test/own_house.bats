load test_helper

listed_names() {
  awk -v kind="${1:-}" 'kind == "" || $1 == kind { print $2 }' "$REPO_DIR/lib/lineage-names" | paste -sd '|'
}

setup() {
  export CALLER="$BATS_TEST_TMPDIR/caller"
  export AGENTS_ROOT="$BATS_TEST_TMPDIR/agents"
  export DEFINITIONS_DIR="$BATS_TEST_TMPDIR/definitions"
  export MISE_TRUSTED_CONFIG_PATHS="$BATS_TEST_TMPDIR"
  export GIT_AUTHOR_NAME="house test"
  export GIT_AUTHOR_EMAIL="house-test@example.invalid"
  export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
  export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
  mkdir -p "$CALLER" "$AGENTS_ROOT" "$DEFINITIONS_DIR"
  LINEAGE="$(listed_names)|KnickKnackLabs|Knick Knack Labs|Bash tool|\[\[ABORT\]\]"
}

@test "the framework ships no household or personal name outside notes/lineage.md and lib/lineage-names" {
  run bash -c "grep -rniwE '$(listed_names)' --exclude-dir=.git --exclude=lineage.md --exclude=lineage-names '$REPO_DIR' | grep -v 'olavostauros/house-framework'"
  [ -z "$output" ]
  [ "$(awk '$1 == "house"' "$REPO_DIR/lib/lineage-names" | wc -l)" -ge 1 ]
}

@test "a fresh house names no lineage, no runner and no mail domain, and keeps one line of attribution" {
  h="$BATS_TEST_TMPDIR/hearth"
  house init hearth --at "$h"
  house agent add vulcan --house "$h" --role backend --owns server/ >/dev/null
  house agent add argus --house "$h" --role review >/dev/null
  house rules add money --house "$h" --binds vulcan >/dev/null
  run bash -c "grep -rniwE '$LINEAGE' --exclude-dir=.git --exclude=mise.toml '$h' '$AGENTS_ROOT' | grep -v 'olavostauros/house-framework'"
  [ -z "$output" ]
  run grep -niwE "$LINEAGE" "$h/mise.toml"
  [ "$output" = $'14:"aqua:KnickKnackLabs/bats-core" = "1.14.0-kkl.3"\n17:registries = ["https://github.com/KnickKnackLabs/bats-core"]' ]
  run grep -rnE '@[^[:space:]`]*\.local' --exclude-dir=.git "$h" "$AGENTS_ROOT"
  [ "$status" -eq 1 ]
  run grep -rn 'Tier 3 for the whole house' "$h/AGENTS.md"
  [ "$status" -eq 1 ]
  [ "$(grep -rh 'house-framework' --exclude-dir=.git "$h" "$AGENTS_ROOT" | wc -l)" -eq 1 ]
  assert_file_contains "$h/README.md" "Started from [house-framework](https://github.com/olavostauros/house-framework)"
  [ "$(git -C "$h" log -1 --format=%s)" = "hearth: bootstrap the household from house-framework" ]
}

@test "the fresh contract holds the authority sections and three guard rules, and asks the owner for a style" {
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
  assert_file_contains "$h/AGENTS.md" "house:decide: house style."
  ! grep -q "Merge, don't squash" "$h/AGENTS.md"
  ! grep -q "Push back when something smells off" "$h/AGENTS.md"
  [ ! -e "$h/notes/house-style.md" ]
}

@test "init --style strict renders the style as a note wired to Read-first and names it in the bootstrap commit" {
  h="$BATS_TEST_TMPDIR/hearth"
  run house init hearth --at "$h" --style strict
  assert_success
  assert_output_contains "create: notes/house-style.md (style: strict)"
  assert_file_contains "$h/notes/house-style.md" "title: house-style"
  assert_file_contains "$h/notes/house-style.md" "**Merge, don't squash.**"
  assert_file_contains "$h/notes/house-style.md" "**Push back when something smells off.**"
  ! grep -qiwE "$LINEAGE" "$h/notes/house-style.md"
  ! grep -q 'house:decide' "$h/notes/house-style.md"
  assert_file_contains "$h/AGENTS.md" "House style is [[house-style]]"
  assert_file_contains "$h/AGENTS.md" '| commit, review, open a PR, or end a session | [`notes/house-style.md`](notes/house-style.md) |'
  ! grep -q 'house:decide: house style' "$h/AGENTS.md"
  ! grep -q "Merge, don't squash" "$h/AGENTS.md"
  [ "$(git -C "$h" log -1 --format=%s)" = "hearth: bootstrap the household from house-framework, with the strict style" ]
  run house init hall --at "$BATS_TEST_TMPDIR/hall" --style loose
  assert_failure
  assert_output_contains "unknown style: loose (known: strict"
  [ ! -e "$BATS_TEST_TMPDIR/hall/AGENTS.md" ]
}

@test "init renders --owner into the contract, and asks when nobody is named" {
  h="$BATS_TEST_TMPDIR/hearth"
  house init hearth --at "$h" --owner "Ada"
  assert_file_contains "$h/AGENTS.md" "The owner is **Ada**: the one human here, who files the queue, merges, and alone widens a rule."
  ! grep -q 'house:decide: who the owner is' "$h/AGENTS.md"
  house init hall --at "$BATS_TEST_TMPDIR/hall"
  assert_file_contains "$BATS_TEST_TMPDIR/hall/AGENTS.md" "house:decide: who the owner is"
  ! grep -q 'The owner is \*\*' "$BATS_TEST_TMPDIR/hall/AGENTS.md"
}

@test "a fresh house asks the owner to decide wherever the framework used to answer, and nowhere else" {
  h="$BATS_TEST_TMPDIR/hearth"
  house init hearth --at "$h"
  house agent add vulcan --house "$h" --role backend --owns server/ >/dev/null
  house agent add argus --house "$h" --role review >/dev/null
  run grep -rc 'house:decide' --exclude-dir=.git "$h" "$AGENTS_ROOT"
  expected="$h/AGENTS.md:5
$h/README.md:1
$h/notes/household-backlog.md:1
$h/notes/vulcan.md:1
$h/notes/argus.md:1"
  [ "$(printf '%s\n' "$output" | grep -v ':0$' | sort)" = "$(printf '%s\n' "$expected" | sort)" ]
  ! grep -q 'house:decide' "$h/notes/housekeeper.md"
  ! grep -rq 'house:decide' "$AGENTS_ROOT"
  make_theirs "$h"
  ! grep -rq 'house:decide' "$h"
  run in_house "$h" test
  assert_success
}
