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
  house init hearth --at "$H" --project "the forge" --no-housekeeper >/dev/null
}

@test "agent add --kind housekeeper adds one to a house created without it" {
  run house agent add hestia --house "$H" --kind housekeeper
  assert_success
  assert_output_contains "roster: hestia (housekeeper)"
  assert_output_contains "its first sweep is the house's first audit"
  grep -q $'^hestia\thousekeeping\t$' "$H/roster.tsv"
  assert_file_contains "$H/notes/hestia.md" "The housekeeper of the forge"
  assert_file_contains "$DEFINITIONS_DIR/hestia.md" "Housekeeper of the hearth household of the forge"
  assert_file_contains "$AGENTS_ROOT/hestia/home/AGENTS.md" "the housekeeper of **the forge**"
}

@test "agent add refuses --owns on a judge or housekeeper and a builder without --owns" {
  run house agent add loki --house "$H" --role tricks --kind judge --owns tricks/
  assert_failure
  assert_output_contains "owns no directory"
  run house agent add thor --house "$H" --role hammer --kind builder
  assert_failure
  assert_output_contains "must --owns"
}

@test "agent add puts a builder on the roster with note, home, and definition" {
  run house agent add vulcan --house "$H" --role backend --owns server/ --charge "Owns the schema and the API."
  assert_success
  assert_output_contains "roster: vulcan (builder)"

  grep -q $'^vulcan\tbackend\tserver/$' "$H/roster.tsv"
  assert_file_contains "$H/notes/vulcan.md" "Owns \`$H/server/\`"
  assert_file_contains "$H/AGENTS.md" "- **vulcan** — backend. Owns \`server/\`: Owns the schema and the API."
  assert_file_contains "$H/AGENTS.md" "| act as vulcan for the first time in a session | [\`notes/vulcan.md\`](notes/vulcan.md) |"

  [ -f "$AGENTS_ROOT/vulcan/home/AGENTS.md" ]
  [ -f "$AGENTS_ROOT/vulcan/home/mise.toml" ]
  [ -f "$AGENTS_ROOT/vulcan/home/SCRATCHPAD.md" ]
  [ -d "$AGENTS_ROOT/vulcan/home/.git" ]
  assert_file_contains "$AGENTS_ROOT/vulcan/home/AGENTS.md" "You own"
  assert_file_contains "$AGENTS_ROOT/vulcan/home/AGENTS.md" "git switch -c vulcan/<short-topic>"

  [ -f "$DEFINITIONS_DIR/vulcan.md" ]
  assert_file_contains "$DEFINITIONS_DIR/vulcan.md" "name: vulcan"
  assert_file_contains "$DEFINITIONS_DIR/vulcan.md" "tools: Read, Grep, Glob, Bash, Edit, Write"
  assert_file_contains "$DEFINITIONS_DIR/vulcan.md" "Backend for the hearth household of the forge"
  ! grep -rq '{{' "$H/notes/vulcan.md" "$AGENTS_ROOT/vulcan/home" "$DEFINITIONS_DIR/vulcan.md"
}

@test "agent add without --owns makes a judge with no Edit or Write" {
  run house agent add argus --house "$H" --role "review and security"
  assert_success
  assert_output_contains "roster: argus (judge)"
  assert_file_contains "$H/AGENTS.md" "- **argus** — review and security. Owns no directory."
  assert_file_contains "$DEFINITIONS_DIR/argus.md" "tools: Read, Grep, Glob, Bash, WebFetch, WebSearch"
  assert_file_contains "$DEFINITIONS_DIR/argus.md" "Judgement only"
  assert_file_contains "$AGENTS_ROOT/argus/home/AGENTS.md" "You own no"
  assert_file_contains "$H/notes/argus.md" "Judgement, not patches"
}

@test "agent add refuses a duplicate and an agent with no role" {
  house agent add vulcan --house "$H" --role backend --owns server/
  run house agent add vulcan --house "$H" --role backend --owns server/
  assert_failure
  assert_output_contains "already on the roster"
  run house agent add loki --house "$H"
  assert_failure
  assert_output_contains "--role is required"
}

@test "agent add honours --no-home and --no-definition and keeps what exists" {
  run house agent add hermes --house "$H" --role messenger --no-home --no-definition
  assert_success
  [ ! -e "$AGENTS_ROOT/hermes" ]
  [ ! -e "$DEFINITIONS_DIR/hermes.md" ]

  mkdir -p "$AGENTS_ROOT/apollo/home"
  printf 'mine\n' > "$AGENTS_ROOT/apollo/home/AGENTS.md"
  printf 'mine\n' > "$DEFINITIONS_DIR/apollo.md"
  run house agent add apollo --house "$H" --role music
  assert_success
  assert_output_contains "keep:"
  [ "$(cat "$AGENTS_ROOT/apollo/home/AGENTS.md")" = "mine" ]
  [ "$(cat "$DEFINITIONS_DIR/apollo.md")" = "mine" ]
}

@test "after agent add the house's own checks and guard know the new agent" {
  house agent add vulcan --house "$H" --role backend --owns server/
  house agent add argus --house "$H" --role review
  run in_house "$H" test
  assert_success

  run in_house "$H" agent-env vulcan
  assert_success
  assert_output_contains "export GIT_AUTHOR_NAME=vulcan"
  assert_output_contains "export GIT_AUTHOR_EMAIL=vulcan@hearth.local"

  run env -u HEARTH_OWNER_COMMIT GIT_AUTHOR_NAME=argus "$H/hooks/agent-identity"
  assert_success
  run env -u HEARTH_OWNER_COMMIT GIT_AUTHOR_NAME=loki "$H/hooks/agent-identity"
  assert_failure
}

@test "agent add resolves the house from the caller's directory" {
  export CALLER="$H"
  run house agent add vulcan --role backend --owns server/
  assert_success
  grep -q '^vulcan' "$H/roster.tsv"
}

@test "agent add rejects a directory that is not a house" {
  run house agent add vulcan --house "$BATS_TEST_TMPDIR" --role backend
  assert_failure
  assert_output_contains "not a house"
}
