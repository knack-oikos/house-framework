load test_helper

setup() {
  house_setup
  H="$BATS_TEST_TMPDIR/hearth"
  house init hearth --at "$H" --project "the forge" >/dev/null
}

@test "a fresh house already has its housekeeper, and there is one per house under one name" {
  grep -q $'^housekeeper\thousekeeping\t\thousekeeper$' "$H/roster.tsv"
  assert_file_contains "$H/notes/housekeeper.md" "The housekeeper of the forge"
  assert_file_contains "$AGENTS_ROOT/hearth/home/AGENTS.md" "the housekeeper of **the forge**"
  [ ! -e "$AGENTS_ROOT/housekeeper" ]
  run house agent add housekeeper --house "$H"
  assert_failure
  assert_output_contains "already on the roster"
  run house agent add housekeeper --house "$H" --owns tidy/
  assert_failure
  assert_output_contains "the housekeeper owns no directory"
  sed -i '/^housekeeper\t/d' "$H/roster.tsv"
  printf 'hestia\thousekeeping\t\thousekeeper\n' >> "$H/roster.tsv"
  run house agent add housekeeper --house "$H"
  assert_failure
  assert_output_contains "already has a housekeeper; a house has exactly one"
}

@test "agent add puts a builder on the roster with note and home, and no harness file" {
  run house agent add vulcan --house "$H" --role backend --owns server/ --charge "Owns the schema and the API."
  assert_success
  assert_output_contains "roster: vulcan (builder)"
  assert_output_contains "its Stance is the framework's for a builder"

  grep -q $'^vulcan\tbackend\tserver/\tbuilder$' "$H/roster.tsv"
  assert_file_contains "$H/notes/vulcan.md" "Owns \`$H/server/\`"
  assert_file_contains "$H/notes/vulcan.md" "The failing case first, then the change, then the gates"
  assert_file_says "$H/notes/vulcan.md" "Narrowing this stance is vulcan's; widening it is the owner's."
  assert_file_contains "$H/AGENTS.md" "- **vulcan** — backend. Owns \`server/\`: Owns the schema and the API."
  assert_file_contains "$H/AGENTS.md" "| act as vulcan for the first time in a session | [\`notes/vulcan.md\`](notes/vulcan.md) |"

  [ -f "$AGENTS_ROOT/vulcan/home/AGENTS.md" ]
  [ -f "$AGENTS_ROOT/vulcan/home/mise.toml" ]
  [ -f "$AGENTS_ROOT/vulcan/home/SCRATCHPAD.md" ]
  [ -d "$AGENTS_ROOT/vulcan/home/.git" ]
  assert_file_contains "$AGENTS_ROOT/vulcan/home/AGENTS.md" "You own"
  assert_file_contains "$AGENTS_ROOT/vulcan/home/AGENTS.md" "git switch -c vulcan/<short-topic>"
  assert_file_contains "$AGENTS_ROOT/vulcan/home/AGENTS.md" "stalls on its passphrase prompt is reported, not"

  assert_file_contains "$AGENTS_ROOT/vulcan/home/AGENTS.md" "$AGENTS_ROOT/vulcan/home"
  [ -z "$(ls -A "$DEFINITIONS_DIR")" ]
  ! grep -rq '{{' "$H/notes/vulcan.md" "$AGENTS_ROOT/vulcan/home"
  ! grep -rqiwE "$(awk '$1 == "runner" { print $2 }' "$REPO_DIR/lib/lineage-names" | paste -sd '|')" "$H" "$AGENTS_ROOT/vulcan/home"
  ! grep -rq 'house:decide' "$H/notes/vulcan.md" "$AGENTS_ROOT/vulcan/home"
}

@test "agent add without --owns makes a judge" {
  run house agent add argus --house "$H" --role "review and security"
  assert_success
  assert_output_contains "roster: argus (judge)"
  assert_output_contains "its Stance is the framework's for a judge"
  grep -q $'^argus\treview and security\t\tjudge$' "$H/roster.tsv"
  assert_file_contains "$H/AGENTS.md" "- **argus** — review and security. Owns no directory."
  assert_file_contains "$AGENTS_ROOT/argus/home/AGENTS.md" "You own no"
  assert_file_contains "$AGENTS_ROOT/argus/home/AGENTS.md" "stalls on its passphrase prompt is reported, not"
  assert_file_contains "$H/notes/argus.md" "Judgement, not patches"
  assert_file_contains "$H/notes/argus.md" "The diff before the description, and the test before the diff"
  assert_file_says "$H/notes/argus.md" "Narrowing this stance is argus's; widening it is the owner's."
  ! grep -q 'house:decide' "$H/notes/argus.md"
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

@test "agent add keeps a home that exists" {
  mkdir -p "$AGENTS_ROOT/apollo/home"
  printf 'mine\n' > "$AGENTS_ROOT/apollo/home/AGENTS.md"
  run house agent add apollo --house "$H" --role music
  assert_success
  assert_output_contains "keep:"
  [ "$(cat "$AGENTS_ROOT/apollo/home/AGENTS.md")" = "mine" ]
}

@test "after agent add the house's own checks and guard know the new agent" {
  house agent add vulcan --house "$H" --role backend --owns server/
  house agent add argus --house "$H" --role review
  run in_house "$H" test
  assert_success

  run in_house "$H" agent-env vulcan
  assert_success
  assert_output_contains "export GIT_AUTHOR_NAME=vulcan"
  assert_output_contains "export GIT_AUTHOR_EMAIL=vulcan@hearth.invalid"

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

@test "agent add renders a charge with an ampersand verbatim" {
  run house agent add caesar --house "$H" --role payments --owns payments/ --charge 'Takes money & refunds it.'
  assert_success
  assert_file_contains "$H/AGENTS.md" "Takes money & refunds it."
  assert_file_contains "$H/notes/caesar.md" "Takes money & refunds it."
  assert_file_contains "$AGENTS_ROOT/caesar/home/AGENTS.md" "Takes money & refunds it."
  ! grep -rq '{{CHARGE}}' "$H/AGENTS.md" "$H/notes/caesar.md" "$AGENTS_ROOT/caesar/home"
}
