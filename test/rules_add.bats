load test_helper

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
  H="$BATS_TEST_TMPDIR/hearth"
  house init hearth --at "$H" >/dev/null
}

@test "rules add inserts a rule set above the marker, bound to an agent" {
  house agent add caesar --house "$H" --role payments --owns payments/
  run house rules add money --house "$H" --binds caesar
  assert_success
  assert_file_contains "$H/AGENTS.md" "### Money rules"
  assert_file_contains "$H/AGENTS.md" "These bind caesar."
  rules_line="$(grep -n '^### Money rules$' "$H/AGENTS.md" | cut -d: -f1)"
  marker_line="$(grep -n '^<!-- house:rules -->$' "$H/AGENTS.md" | cut -d: -f1)"
  [ "$rules_line" -lt "$marker_line" ]
  run in_house "$H" test
  assert_success
}

@test "rules add without --binds uses the generic binding" {
  run house rules add data --house "$H"
  assert_success
  assert_file_contains "$H/AGENTS.md" "These bind the agent whose charge they name."
}

@test "rules add refuses an unknown set, an unknown agent, and a repeat" {
  run house rules add vibes --house "$H"
  assert_failure
  assert_output_contains "no such rule set"
  run house rules add money --house "$H" --binds nobody
  assert_failure
  assert_output_contains "not on the roster"
  house rules add review --house "$H"
  run house rules add review --house "$H"
  assert_failure
  assert_output_contains "already has"
}

@test "every shipped rule set inserts cleanly" {
  for set in money identity data review; do
    run house rules add "$set" --house "$H"
    assert_success
  done
  ! grep -q '{{BINDS}}' "$H/AGENTS.md"
}
