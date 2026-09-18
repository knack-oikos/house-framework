load test_helper

@test "examples/ is a fresh render of the templates, and the check names a drift" {
  run house examples
  assert_success
  assert_output_contains "matches a fresh render"
  cp -R "$REPO_DIR/examples" "$BATS_TEST_TMPDIR/examples"
  printf 'drift\n' >> "$BATS_TEST_TMPDIR/examples/example/README.md"
  rm "$BATS_TEST_TMPDIR/examples/agents/example/home/SCRATCHPAD.md"
  run env HOUSE_EXAMPLES_DIR="$BATS_TEST_TMPDIR/examples" bash -c 'house "$@"' _ examples
  assert_failure
  assert_output_contains "example/README.md"
  assert_output_contains "Only in"
  assert_output_contains "SCRATCHPAD.md"
  assert_output_contains "has drifted from the templates"
  assert_output_contains "mise run examples --write"
  [ -z "$(ls -A "$AGENTS_ROOT")" ]
}

@test "examples --write renders one house and one home with fixed paths and dates, names no harness, and touches nothing real" {
  run env HOUSE_EXAMPLES_DIR="$BATS_TEST_TMPDIR/examples" bash -c 'house "$@"' _ examples --write
  assert_success
  assert_output_contains "write: $BATS_TEST_TMPDIR/examples is a fresh render of the templates"
  e="$BATS_TEST_TMPDIR/examples"
  for f in example/AGENTS.md example/README.md example/roster.tsv example/hooks/agent-identity \
           example/notes/housekeeper.md example/notes/builder.md agents/example/home/AGENTS.md; do
    [ -f "$e/$f" ]
  done
  [ "$(ls "$e")" = $'agents\nexample' ]
  [ "$(ls "$e/agents")" = "example" ]
  [ -x "$e/example/hooks/agent-identity" ]
  [ ! -e "$e/example/.git" ]
  [ ! -e "$e/agents/example/home/.git" ]
  grep -q $'^builder\timplementation\tsrc/\tbuilder$' "$e/example/roster.tsv"
  assert_file_contains "$e/example/AGENTS.md" '`~/example` is a single shared checkout'
  assert_file_contains "$e/example/AGENTS.md" "house:decide: who the owner is"
  assert_file_contains "$e/example/notes/housekeeper.md" "created: 2026-01-01"
  assert_file_contains "$e/example/README.md" "on 2026-01-01, at v0.0.0."
  assert_file_contains "$e/agents/example/home/AGENTS.md" "~/agents/example/home"
  ! grep -rq '{{[A-Z_]*}}' "$e"
  ! grep -rqi 'claude' "$e" "$REPO_DIR/.mise/tasks/examples"
  ! grep -rqi 'claude' "$REPO_DIR/examples"
  [ -z "$(ls -A "$AGENTS_ROOT")" ]
  [ -z "$(ls -A "$DEFINITIONS_DIR")" ]
  run env HOUSE_EXAMPLES_DIR="$e" bash -c 'house "$@"' _ examples
  assert_success
}
