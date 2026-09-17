load test_helper

@test "examples/ is a fresh render of the templates, and the check names a drift" {
  run house examples
  assert_success
  assert_output_contains "matches a fresh render"
  cp -R "$REPO_DIR/examples" "$BATS_TEST_TMPDIR/examples"
  printf 'drift\n' >> "$BATS_TEST_TMPDIR/examples/hearth/README.md"
  rm "$BATS_TEST_TMPDIR/examples/agents/vulcan/home/SCRATCHPAD.md"
  run env HOUSE_EXAMPLES_DIR="$BATS_TEST_TMPDIR/examples" bash -c 'house "$@"' _ examples
  assert_failure
  assert_output_contains "hearth/README.md"
  assert_output_contains "Only in"
  assert_output_contains "SCRATCHPAD.md"
  assert_output_contains "has drifted from the templates"
  assert_output_contains "mise run examples --write"
  [ -z "$(ls -A "$AGENTS_ROOT")" ]
}

@test "examples --write renders into the given directory with fixed paths and dates, and touches nothing real" {
  run env HOUSE_EXAMPLES_DIR="$BATS_TEST_TMPDIR/examples" bash -c 'house "$@"' _ examples --write
  assert_success
  assert_output_contains "write: $BATS_TEST_TMPDIR/examples is a fresh render of the templates"
  e="$BATS_TEST_TMPDIR/examples"
  for f in hearth/AGENTS.md hearth/README.md hearth/roster.tsv hearth/hooks/agent-identity hearth/notes/vulcan.md \
           agents/hearth/home/AGENTS.md agents/vulcan/home/AGENTS.md agents/argus/home/AGENTS.md; do
    [ -f "$e/$f" ]
  done
  [ -x "$e/hearth/hooks/agent-identity" ]
  [ ! -e "$e/hearth/.git" ]
  [ ! -e "$e/agents/vulcan/home/.git" ]
  assert_file_contains "$e/hearth/AGENTS.md" '`~/Work/hearth` is a single shared checkout'
  assert_file_contains "$e/hearth/AGENTS.md" "house:decide: who the owner is"
  assert_file_contains "$e/hearth/AGENTS.md" "### Review rules"
  assert_file_contains "$e/hearth/notes/housekeeper.md" "created: 2026-01-01"
  assert_file_contains "$e/agents/vulcan/home/AGENTS.md" "~/agents/vulcan/home"
  ! grep -rq '{{[A-Z_]*}}' "$e"
  [ -z "$(ls -A "$AGENTS_ROOT")" ]
  [ -z "$(ls -A "$DEFINITIONS_DIR")" ]
  run env HOUSE_EXAMPLES_DIR="$e" bash -c 'house "$@"' _ examples
  assert_success
}
