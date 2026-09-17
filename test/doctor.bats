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

@test "doctor fails a fresh house, naming every undecided marker by file and line, and is healthy once the owner has answered them" {
  run house doctor --house "$H"
  assert_failure
  assert_output_contains "fail: decide: AGENTS.md:6:what this household is and why it exists, in the owner's"
  assert_output_contains "fail: decide: AGENTS.md:"
  assert_output_contains ":how the owner merges"
  assert_output_contains ":house style."
  assert_output_contains ":the agents' author domain."
  assert_output_contains ":who the owner is"
  assert_output_contains "fail: decide: README.md:"
  assert_output_contains ":which of these this house wants"
  assert_output_contains "fail: decide: notes/household-backlog.md:"
  assert_output_contains ":the first changes this house wants"
  assert_output_contains "next: each decide:, placeholder:, stance: and lineage: line is the owner's to answer"
  ! [[ "$output" == *"fail: decide: notes/housekeeper.md"* ]]
  make_theirs "$H"
  run house doctor --house "$H"
  assert_success
  assert_output_contains "doctor: healthy"
  assert_output_contains "ok:   the house is the owner's: no house:decide marker, no {{placeholder}}, no unwritten Stance, no lineage name"
  assert_output_contains "warn: pre-commit guard not installed"
}

@test "doctor warns about an empty roster, the housekeeper and the guard" {
  rm -rf "$H" "$AGENTS_ROOT/hearth"
  house init hearth --at "$H" --no-housekeeper >/dev/null
  make_theirs "$H"
  run house doctor --house "$H"
  assert_success
  assert_output_contains "doctor: healthy"
  assert_output_contains "warn: roster is empty"
  assert_output_contains "warn: no housekeeper"
  assert_output_contains "warn: pre-commit guard not installed"
}

@test "doctor fails an agent whose Stance the owner has not written, in either wording" {
  make_theirs "$H"
  house agent add vulcan --house "$H" --role backend --owns server/ >/dev/null
  run house doctor --house "$H"
  assert_failure
  assert_output_contains "fail: decide: notes/vulcan.md:"
  assert_output_contains ":what vulcan is judged on, what the stack is, and which"
  assert_output_contains "doctor: 1 failing"
  make_theirs "$H"
  printf 'The owner writes this section when vulcan first wakes.\n' >> "$H/notes/vulcan.md"
  run house doctor --house "$H"
  assert_failure
  assert_output_contains "fail: stance: notes/vulcan.md:$(wc -l < "$H/notes/vulcan.md"): unwritten"
}

@test "doctor fails a leftover placeholder in the house or in a home" {
  make_theirs "$H"
  printf '{{HOUSE_NAME}}\n' >> "$H/README.md"
  printf 'the home of {{AGENT}}\n' >> "$AGENTS_ROOT/hearth/home/SCRATCHPAD.md"
  run house doctor --house "$H"
  assert_failure
  assert_output_contains "fail: placeholder: README.md:$(wc -l < "$H/README.md"):{{HOUSE_NAME}}"
  assert_output_contains "fail: placeholder: $AGENTS_ROOT/hearth/home/SCRATCHPAD.md:$(wc -l < "$AGENTS_ROOT/hearth/home/SCRATCHPAD.md"):{{AGENT}}"
  assert_output_contains "doctor: 2 failing"
}

@test "doctor fails a lineage name, but not the house's own name, a tool pin, or a package a preset declared" {
  make_theirs "$H"
  printf 'as oikos does, and as Fold did\n' >> "$H/notes/work-queue.md"
  run house doctor --house "$H"
  assert_failure
  assert_output_contains "fail: lineage: notes/work-queue.md:$(wc -l < "$H/notes/work-queue.md"):as oikos does, and as Fold did"
  assert_output_contains "doctor: 1 failing"
  ! [[ "$output" == *"fail: lineage: mise.toml"* ]]
  printf 'read KnickKnackLabs/notes\n' >> "$H/notes/work-queue.md"
  run house doctor --house "$H"
  assert_output_contains "fail: lineage: notes/work-queue.md:$(wc -l < "$H/notes/work-queue.md"):read KnickKnackLabs/notes"

  a="$BATS_TEST_TMPDIR/agora"
  house init agora --at "$a" --project "the Agora" >/dev/null
  make_theirs "$a"
  run house doctor --house "$a"
  assert_success

  n="$BATS_TEST_TMPDIR/hall"
  house init hall --at "$n" --with notes >/dev/null
  make_theirs "$n"
  printf 'notes/** filter=git-crypt diff=git-crypt\n' > "$n/.gitattributes"
  mkdir -p "$n/.git-crypt/keys/default/0"
  assert_file_contains "$n/AGENTS.md" "KnickKnackLabs/notes"
  run house doctor --house "$n"
  assert_success
}

@test "doctor is quiet once the guard is installed and an agent has everything, and never looks for a harness" {
  in_house "$H" install-hooks >/dev/null
  house agent add vulcan --house "$H" --role backend --owns server/ >/dev/null
  make_theirs "$H"
  run house doctor --house "$H"
  assert_success
  assert_output_contains "ok:   housekeeper: home at $AGENTS_ROOT/hearth/home"
  assert_output_contains "ok:   vulcan: notes/vulcan.md"
  assert_output_contains "ok:   vulcan: home at"
  ! [[ "$output" == *"warn:"* ]]
  ! [[ "$output" == *"definition"* ]]
}

@test "doctor fails on a second housekeeper or one under another name" {
  printf 'hestia\thousekeeping\t\thousekeeper\n' >> "$H/roster.tsv"
  run house doctor --house "$H"
  assert_failure
  assert_output_contains "fail: hestia: a housekeeper must be named housekeeper"
  assert_output_contains "fail: roster lists 2 housekeepers"
}

@test "doctor reads a roster without a kind column" {
  house agent add vulcan --house "$H" --role backend --owns server/ >/dev/null
  house agent add argus --house "$H" --role review >/dev/null
  make_theirs "$H"
  awk -F '\t' 'BEGIN { OFS = "\t" } /^#/ { print; next } { print $1, $2, $3 }' "$H/roster.tsv" > "$H/roster.new"
  mv "$H/roster.new" "$H/roster.tsv"
  run house doctor --house "$H"
  assert_success
  assert_output_contains "ok:   housekeeper: home at $AGENTS_ROOT/hearth/home"
  assert_output_contains "ok:   vulcan: home at $AGENTS_ROOT/vulcan/home"
  assert_output_contains "ok:   argus: home at $AGENTS_ROOT/argus/home"
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
