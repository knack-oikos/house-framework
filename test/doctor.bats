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

@test "doctor is healthy on a fresh house and warns about the empty roster and the guard" {
  rm -rf "$H"
  house init hearth --at "$H" --no-housekeeper >/dev/null
  run house doctor --house "$H"
  assert_success
  assert_output_contains "doctor: healthy"
  assert_output_contains "warn: roster is empty"
  assert_output_contains "warn: pre-commit guard not installed"
}

@test "doctor is quiet once the guard is installed and an agent has everything" {
  in_house "$H" install-hooks >/dev/null
  house agent add vulcan --house "$H" --role backend --owns server/ >/dev/null
  run house doctor --house "$H"
  assert_success
  assert_output_contains "ok:   housekeeper: definition at"
  assert_output_contains "ok:   vulcan: notes/vulcan.md"
  assert_output_contains "ok:   vulcan: home at"
  assert_output_contains "ok:   vulcan: definition at"
  ! [[ "$output" == *"warn:"* ]]
}

@test "doctor fails when an agent is on the roster but not in the contract" {
  house agent add vulcan --house "$H" --role backend --owns server/ >/dev/null
  sed -i '/^- \*\*vulcan\*\* — /d' "$H/AGENTS.md"
  run house doctor --house "$H"
  assert_failure
  assert_output_contains "fail: vulcan: not listed"
}

@test "doctor fails when a marker or an authority section is gone" {
  sed -i '/^<!-- house:rules -->$/d' "$H/AGENTS.md"
  sed -i 's/^#### The two-key rule$/#### Two keys/' "$H/AGENTS.md"
  run house doctor --house "$H"
  assert_failure
  assert_output_contains "lacks marker <!-- house:rules -->"
  assert_output_contains "lacks section: #### The two-key rule"
}

@test "doctor fails when the guard is not executable" {
  chmod -x "$H/hooks/agent-identity"
  run house doctor --house "$H"
  assert_failure
  assert_output_contains "hooks/agent-identity is not executable"
}
