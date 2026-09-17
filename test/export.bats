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
  house init hearth --at "$H" --project "the forge" >/dev/null
  house agent add vulcan --house "$H" --role backend --owns server/ >/dev/null
  house agent add argus --house "$H" --role "review and security" >/dev/null
}

@test "export claude-code writes one definition per roster agent, by kind" {
  run house export claude-code --house "$H"
  assert_success
  assert_output_contains "create: $DEFINITIONS_DIR/vulcan.md (vulcan, builder)"
  assert_output_contains "create: $DEFINITIONS_DIR/argus.md (argus, judge)"
  assert_output_contains "create: $DEFINITIONS_DIR/hearth.md (housekeeper, housekeeper)"

  assert_file_contains "$DEFINITIONS_DIR/vulcan.md" "name: vulcan"
  assert_file_contains "$DEFINITIONS_DIR/vulcan.md" "tools: Read, Grep, Glob, Bash, Edit, Write"
  assert_file_contains "$DEFINITIONS_DIR/vulcan.md" "Backend for the hearth household of the forge"
  assert_file_contains "$DEFINITIONS_DIR/vulcan.md" "$AGENTS_ROOT/vulcan/home"

  assert_file_contains "$DEFINITIONS_DIR/argus.md" "name: argus"
  assert_file_contains "$DEFINITIONS_DIR/argus.md" "tools: Read, Grep, Glob, Bash, WebFetch, WebSearch"
  assert_file_contains "$DEFINITIONS_DIR/argus.md" "Judgement only"

  for d in vulcan argus hearth; do
    assert_file_contains "$DEFINITIONS_DIR/$d.md" "stalls on a passphrase prompt"
    assert_file_contains "$DEFINITIONS_DIR/$d.md" "never to work around by turning signing off"
  done

  ! grep -rq '{{' "$DEFINITIONS_DIR"
}

@test "the housekeeper's definition is named after the house" {
  house export claude-code --house "$H" >/dev/null
  [ ! -e "$DEFINITIONS_DIR/housekeeper.md" ]
  assert_file_contains "$DEFINITIONS_DIR/hearth.md" "name: hearth"
  assert_file_contains "$DEFINITIONS_DIR/hearth.md" "You are the hearth household itself"
  assert_file_contains "$DEFINITIONS_DIR/hearth.md" "Your roster name and git author are"
  assert_file_contains "$DEFINITIONS_DIR/hearth.md" "no GitHub account, no signing key and"
  assert_file_contains "$DEFINITIONS_DIR/hearth.md" "tools: Read, Grep, Glob, Bash, Edit, Write"
  assert_file_contains "$DEFINITIONS_DIR/hearth.md" "$AGENTS_ROOT/hearth/home"
}

@test "export keeps an existing definition unless --force, and --agent picks one" {
  printf 'mine\n' > "$DEFINITIONS_DIR/vulcan.md"
  run house export claude-code --house "$H" --agent vulcan
  assert_success
  assert_output_contains "keep: $DEFINITIONS_DIR/vulcan.md exists"
  [ "$(cat "$DEFINITIONS_DIR/vulcan.md")" = "mine" ]
  [ ! -e "$DEFINITIONS_DIR/argus.md" ]

  run house export claude-code --house "$H" --agent vulcan --force
  assert_success
  assert_file_contains "$DEFINITIONS_DIR/vulcan.md" "name: vulcan"
  [ ! -e "$DEFINITIONS_DIR/argus.md" ]
}

@test "export honours --to and refuses an agent not on the roster" {
  run house export claude-code --house "$H" --to "$BATS_TEST_TMPDIR/elsewhere"
  assert_success
  [ -f "$BATS_TEST_TMPDIR/elsewhere/vulcan.md" ]
  [ -z "$(ls -A "$DEFINITIONS_DIR")" ]
  run house export claude-code --house "$H" --agent loki
  assert_failure
  assert_output_contains "not on the roster"
}

@test "export says so on an empty roster" {
  rm -rf "$H" "$AGENTS_ROOT/hearth"
  house init hearth --at "$H" --no-housekeeper >/dev/null
  run house export claude-code --house "$H"
  assert_success
  assert_output_contains "nothing to export"
}
