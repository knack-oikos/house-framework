load test_helper

setup() {
  house_setup
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
