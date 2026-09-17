load test_helper

pin_version() {
  sed -n 's/.*= "\(.*\)"$/\1/p' "$REPO_DIR/templates/preset/$1/pin"
}

@test "init --with notes,shimmer declares both with exact pins and the shiv plugin, and welcome reports them" {
  h="$BATS_TEST_TMPDIR/hearth"
  run house init hearth --at "$h" --with notes,shimmer
  assert_success
  assert_output_contains "preset: notes"
  assert_output_contains "preset: shimmer"
  assert_output_contains "next: cd $h && notes setup --gpg-key <fingerprint> — the owner's turn"
  assert_file_contains "$h/mise.toml" "$(cat "$REPO_DIR/templates/preset/notes/pin")"
  assert_file_contains "$h/mise.toml" "$(cat "$REPO_DIR/templates/preset/shimmer/pin")"
  grep -qx '\[plugins\]' "$h/mise.toml"
  grep -qx 'shiv = "https://github.com/KnickKnackLabs/vfox-shiv"' "$h/mise.toml"
  [ -x "$h/.mise/tasks/agent/list" ]
  [ -f "$h/test/notes.bats" ]
  [ -f "$h/test/shimmer.bats" ]
  ! grep -rq '{{[A-Z_]*}}' "$h/AGENTS.md" "$h/README.md" "$h/mise.toml" "$h/notes" "$h/.mise" "$h/test"
  [ -z "$(git -C "$h" status --porcelain)" ]
  run in_house "$h" welcome
  assert_success
  assert_output_contains "== packages =="
  assert_output_contains "notes $(pin_version notes):"
  assert_output_contains "shimmer $(pin_version shimmer):"
  assert_output_contains "notes/: plaintext → cd $h && notes setup --gpg-key <fingerprint>"
  assert_output_contains "agent:list: nobody yet"
}

@test "init --with puts presets in canonical order, dedupes, and refuses one it does not know" {
  house init hearth --at "$BATS_TEST_TMPDIR/hearth" --with shimmer,notes,notes
  [ "$(grep '^"shiv:' "$BATS_TEST_TMPDIR/hearth/mise.toml" | wc -l)" -eq 2 ]
  [ "$(grep '^"shiv:' "$BATS_TEST_TMPDIR/hearth/mise.toml" | head -1)" = "$(cat "$REPO_DIR/templates/preset/notes/pin")" ]
  run house init hall --at "$BATS_TEST_TMPDIR/hall" --with secrets
  assert_failure
  assert_output_contains "unknown preset: secrets (known: notes shimmer"
  [ ! -e "$BATS_TEST_TMPDIR/hall/AGENTS.md" ]
}

@test "init without --with declares no package, keeps notes plaintext, and renders no packages section" {
  h="$BATS_TEST_TMPDIR/hearth"
  house init hearth --at "$h"
  ! grep -q 'shiv' "$h/mise.toml"
  ! grep -q '\[plugins\]' "$h/mise.toml"
  ! grep -q 'packages' "$h/.mise/tasks/welcome"
  assert_file_contains "$h/AGENTS.md" "**Notes are plaintext here.**"
  assert_file_contains "$h/notes/household-backlog.md" '### Encrypt `notes/` with git-crypt'
  assert_file_contains "$h/README.md" "shared notes, plaintext. Identity"
  assert_file_contains "$h/README.md" 'Compared with oikos: no git-crypt on `notes/`, no per-agent GitHub identity'
  [ ! -e "$h/.mise/tasks/agent" ]
  [ ! -e "$h/test/notes.bats" ]
  run in_house "$h" welcome
  assert_success
  ! [[ "$output" == *"== packages =="* ]]
}

@test "--with notes rewrites the record and leaves the loosenings table empty" {
  h="$BATS_TEST_TMPDIR/hearth"
  house init hearth --at "$h" --with notes
  assert_file_contains "$h/AGENTS.md" "**Notes are encrypted here**"
  assert_file_contains "$h/AGENTS.md" "notes commit -m"
  assert_file_contains "$h/AGENTS.md" "cd $h && notes setup --gpg-key <fingerprint>"
  assert_file_contains "$h/AGENTS.md" '- **notes** — `shiv:notes`'
  assert_file_contains "$h/AGENTS.md" "None granted yet."
  ! grep -q "Notes are plaintext here" "$h/AGENTS.md"
  ! grep -q '### Encrypt `notes/` with git-crypt' "$h/notes/household-backlog.md"
  assert_file_contains "$h/notes/household-backlog.md" "### Give each builder and judge its own GitHub identity"
  assert_file_contains "$h/README.md" 'encrypted with git-crypt through `notes`'
  assert_file_contains "$h/README.md" "Compared with oikos: no per-agent GitHub identity"
  [ ! -e "$h/.mise/tasks/agent" ]
  [ ! -e "$h/test/shimmer.bats" ]
}

@test "--with notes in an embedded house names the notes dir relative to the project" {
  project="$(make_project)"
  run house init hall --at "$project/hall" --embedded --with notes
  assert_success
  assert_output_contains "next: cd $project && notes setup --gpg-key <fingerprint> --dir hall/notes"
  assert_file_contains "$project/hall/AGENTS.md" "--dir hall/notes"
  run in_house "$project/hall" welcome
  assert_success
  assert_output_contains "hall/notes/: plaintext → cd $project && notes setup --gpg-key <fingerprint> --dir hall/notes"
  run house doctor --house "$project/hall"
  assert_failure
  assert_output_contains "fail: notes: hall/notes/ is not encrypted → cd $project && notes setup --gpg-key <fingerprint> --dir hall/notes"
  printf 'hall/notes/** filter=git-crypt diff=git-crypt\n' > "$project/.gitattributes"
  run house doctor --house "$project/hall"
  assert_success
  assert_output_contains "ok:   notes: hall/notes/** is encrypted in .gitattributes"
}

@test "--with shimmer wires agent:list to the roster minus the housekeeper and leaves agent-env as the identity" {
  h="$BATS_TEST_TMPDIR/hearth"
  house init hearth --at "$h" --with shimmer
  house agent add vulcan --house "$h" --role backend --owns server/ >/dev/null
  house agent add argus --house "$h" --role review >/dev/null
  run in_house "$h" agent:list
  assert_success
  [ "$output" = $'vulcan\nargus' ]
  [ -x "$h/.mise/tasks/agent-env" ]
  ! grep -rq 'secrets' "$h/.mise"
  assert_file_contains "$h/AGENTS.md" "It is not the identity path"
  assert_file_contains "$h/AGENTS.md" "**Notes are plaintext here.**"
  run in_house "$h" welcome
  assert_success
  assert_output_contains "agent:list: vulcan argus"
}

@test "a house with presets passes its own checks" {
  h="$BATS_TEST_TMPDIR/hearth"
  house init hearth --at "$h" --with notes,shimmer
  run in_house "$h" test
  assert_success
  assert_output_contains "mise.toml pins notes to an exact release"
  assert_output_contains "agent:list prints the roster minus the housekeeper"
}

@test "welcome reports a declared package that is not installed, and installs nothing" {
  h="$BATS_TEST_TMPDIR/hearth"
  house init hearth --at "$h" --with notes
  run env MISE_DATA_DIR="$BATS_TEST_TMPDIR/mise-data" bash -c 'in_house "$@"' _ "$h" welcome
  assert_success
  assert_output_contains "notes $(pin_version notes): missing → mise install"
  [ ! -e "$BATS_TEST_TMPDIR/mise-data/installs" ]
}

@test "doctor checks a declared package: the plugin, the exact pin, and the wiring" {
  h="$BATS_TEST_TMPDIR/hearth"
  house init hearth --at "$h" --with notes,shimmer
  run house doctor --house "$h"
  assert_failure
  assert_output_contains "ok:   mise.toml declares the shiv plugin"
  assert_output_contains "ok:   shiv:notes $(pin_version notes): exact pin"
  assert_output_contains "ok:   shiv:shimmer $(pin_version shimmer): exact pin"
  assert_output_contains "fail: notes: notes/ is not encrypted → cd $h && notes setup --gpg-key <fingerprint>"
  assert_output_contains "ok:   shimmer: agent:list prints the roster minus the housekeeper"
  assert_output_contains "doctor: 1 failing"
  printf 'notes/** filter=git-crypt diff=git-crypt\n' > "$h/.gitattributes"
  run house doctor --house "$h"
  assert_success
  assert_output_contains "ok:   notes: notes/** is encrypted in .gitattributes"
}

@test "doctor fails a floating pin, a missing plugin line, and a broken agent:list" {
  h="$BATS_TEST_TMPDIR/hearth"
  house init hearth --at "$h" --with shimmer
  sed -i 's/^"shiv:shimmer" = ".*"$/"shiv:shimmer" = "0.1"/' "$h/mise.toml"
  run house doctor --house "$h"
  assert_failure
  assert_output_contains "fail: shiv:shimmer 0.1: a range, not a release"
  sed -i '/^\[plugins\]$/d' "$h/mise.toml"
  chmod -x "$h/.mise/tasks/agent/list"
  run house doctor --house "$h"
  assert_failure
  assert_output_contains "fail: mise.toml pins a shiv package without [plugins]"
  assert_output_contains "fail: shimmer: .mise/tasks/agent/list missing or not executable"
}

@test "doctor warns about a declared package that is not installed and never installs it" {
  h="$BATS_TEST_TMPDIR/hearth"
  house init hearth --at "$h" --with notes
  printf 'notes/** filter=git-crypt diff=git-crypt\n' > "$h/.gitattributes"
  run env MISE_DATA_DIR="$BATS_TEST_TMPDIR/mise-data" bash -c 'house "$@"' _ doctor --house "$h"
  assert_success
  assert_output_contains "warn: shiv:notes $(pin_version notes): not installed → mise -C $h install"
  [ ! -e "$BATS_TEST_TMPDIR/mise-data/installs" ]
}
