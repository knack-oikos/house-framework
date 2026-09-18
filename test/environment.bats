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
  make_theirs "$H"
  in_house "$H" install-hooks >/dev/null
  BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$BIN"
  ln -s "$(command -v mise)" "$BIN/mise"
  printf '#!/usr/bin/env bash\n' > "$BIN/jq"
  chmod +x "$BIN/jq"
}

doctor_with() {
  run env "$@" bash -c 'house "$@"' _ doctor --house "$H"
}

path_without() {
  local farm="$BATS_TEST_TMPDIR/path-without" dir f name
  mkdir -p "$farm"
  IFS=: read -ra dirs <<< "$PATH"
  for dir in "${dirs[@]}"; do
    for f in "$dir"/*; do
      name="${f##*/}"
      if [ -x "$f" ] && [ "$name" != "$1" ] && [ ! -e "$farm/$name" ]; then ln -s "$f" "$farm/$name"; fi
    done
  done
  printf '%s' "$farm"
}

@test "doctor reports every environment line ok when the tool has what it needs" {
  doctor_with PATH="$BIN:$PATH:$HOME/.local/bin"
  assert_success
  assert_output_contains "ok:   bash $(bash --version | sed -n '1s/.*version \([0-9][0-9.]*\).*/\1/p')"
  assert_output_contains "ok:   git $(git --version | sed -n '1s/^git version \([0-9][0-9.]*\).*/\1/p')"
  assert_output_contains "ok:   git user.name"
  assert_output_contains "ok:   git user.email"
  assert_output_contains "ok:   mise on PATH"
  assert_output_contains "ok:   jq on PATH"
  assert_output_contains "ok:   ~/.local/bin on PATH"
  assert_output_contains "ok:   framework: made at $(house version), this tool's version"
  ! [[ "$output" == *"warn:"* ]]
  ! [[ "$output" == *"note:"* ]]
}

@test "doctor fails without a git identity, naming the key to set" {
  doctor_with -u GIT_AUTHOR_NAME -u GIT_AUTHOR_EMAIL -u GIT_COMMITTER_NAME -u GIT_COMMITTER_EMAIL
  assert_failure
  assert_output_contains "fail: git user.name is unset, so house init cannot commit → git config --global user.name"
  assert_output_contains "fail: git user.email is unset, so house init cannot commit → git config --global user.email"
  assert_output_contains "doctor: 2 failing"
  git -C "$H" config user.name "Ada"
  git -C "$H" config user.email "ada@example.invalid"
  doctor_with -u GIT_AUTHOR_NAME -u GIT_AUTHOR_EMAIL -u GIT_COMMITTER_NAME -u GIT_COMMITTER_EMAIL
  assert_success
  assert_output_contains "ok:   git user.email"
}

@test "doctor warns when the shim would run without jq and when ~/.local/bin is off PATH" {
  farm="$(path_without jq)"
  doctor_with PATH="$farm"
  assert_success
  assert_output_contains "warn: jq is not on PATH: without it the house shim runs 'house agent add' as 'mise run agent add' → install jq"
  assert_output_contains "warn: ~/.local/bin is not on PATH, and shiv and mise install there → export PATH=\"\$HOME/.local/bin:\$PATH\""
  assert_output_contains "ok:   mise on PATH"
  doctor_with PATH="$farm" -u HOUSE_CALLER_PWD
  ! [[ "$output" == *"jq"* ]]
}

@test "doctor fails a bash below 4 and a git below 2.28" {
  real_bash="$(command -v bash)"
  real_git="$(command -v git)"
  printf '#!%s\n[ "$1" = --version ] && { echo "GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin)"; exit 0; }\nexec %s "$@"\n' "$real_bash" "$real_bash" > "$BIN/bash"
  printf '#!%s\n[ "$1" = --version ] && { echo "git version 2.20.1"; exit 0; }\nexec %s "$@"\n' "$real_bash" "$real_git" > "$BIN/git"
  chmod +x "$BIN/bash" "$BIN/git"
  doctor_with PATH="$BIN:$PATH"
  assert_failure
  assert_output_contains "fail: bash 3.2.57: house needs bash 4 or newer first on PATH"
  assert_output_contains "fail: git 2.20.1: house init needs git 2.28 or newer for git init -b"
  assert_output_contains "doctor: 2 failing"
}

@test "doctor notes the framework version a house records against the one checking it, and never fails on it" {
  doctor_with HOUSE_FRAMEWORK_VERSION=v5.0.0
  assert_success
  assert_output_contains "note: framework: made at $(house version); this tool is v5.0.0"
  sed -i '/^on [0-9-]*, at /d' "$H/README.md"
  doctor_with
  assert_success
  assert_output_contains "note: framework: the README records no framework version (this tool is $(house version))"
}

@test "doctor checks that a pinned package is named by a source file or an index on this machine" {
  n="$BATS_TEST_TMPDIR/hall"
  house init hall --at "$n" --with notes >/dev/null
  make_theirs "$n"
  printf 'notes/** filter=git-crypt diff=git-crypt\n' > "$n/.gitattributes"
  mkdir -p "$n/.git-crypt/keys/default/0"
  H="$n"
  src="$BATS_TEST_TMPDIR/sources"
  data="$BATS_TEST_TMPDIR/mise-data"
  mkdir -p "$src"
  doctor_with SHIV_SOURCES_DIR="$src" MISE_DATA_DIR="$data" SHIV_INSTALL_PATH="$BATS_TEST_TMPDIR/no-cli"
  assert_success
  assert_output_contains "warn: shiv:notes: not named by any source file under $src, and no shiv index is on this machine yet"
  assert_output_contains "needs $src/notes.json"
  mkdir -p "$data/shiv-backend/shiv"
  printf '{\n  "other": "example/other"\n}\n' > "$data/shiv-backend/shiv/sources.json"
  doctor_with SHIV_SOURCES_DIR="$src" MISE_DATA_DIR="$data" SHIV_INSTALL_PATH="$BATS_TEST_TMPDIR/no-cli"
  assert_failure
  assert_output_contains "fail: shiv:notes: not named by any source file under $src or by $data/shiv-backend/shiv/sources.json → $src/notes.json"
  assert_output_contains "doctor: 1 failing"
  printf '{"notes": "example/notes"}\n' > "$src/mine.json"
  doctor_with SHIV_SOURCES_DIR="$src" MISE_DATA_DIR="$data" SHIV_INSTALL_PATH="$BATS_TEST_TMPDIR/no-cli"
  assert_success
  assert_output_contains "ok:   shiv:notes: named by $src/mine.json"
  rm "$src/mine.json"
  printf '{\n  "notes": "example/notes"\n}\n' > "$data/shiv-backend/shiv/sources.json"
  doctor_with SHIV_SOURCES_DIR="$src" MISE_DATA_DIR="$data" SHIV_INSTALL_PATH="$BATS_TEST_TMPDIR/no-cli"
  assert_success
  assert_output_contains "ok:   shiv:notes: named by $data/shiv-backend/shiv/sources.json"
  [ ! -e "$data/installs" ]
}

@test "doctor warns about a floating shiv range in the global mise config, and only when the house has pins" {
  n="$BATS_TEST_TMPDIR/hall"
  house init hall --at "$n" --with notes >/dev/null
  make_theirs "$n"
  printf 'notes/** filter=git-crypt diff=git-crypt\n' > "$n/.gitattributes"
  mkdir -p "$n/.git-crypt/keys/default/0"
  src="$BATS_TEST_TMPDIR/sources"
  mkdir -p "$src"
  printf '{"notes": "example/notes"}\n' > "$src/mine.json"
  global="$BATS_TEST_TMPDIR/global.toml"
  printf '[tools]\n"shiv:notes" = "latest"\n"shiv:shimmer" = "0.5.0"\n' > "$global"
  doctor_with
  H="$n"
  doctor_with SHIV_SOURCES_DIR="$src" MISE_GLOBAL_CONFIG_FILE="$global"
  assert_success
  assert_output_contains "warn: $global: shiv:notes latest is a range; a floating range in the global mise config deadlocks the nested install on release day (https://github.com/KnickKnackLabs/vfox-shiv/issues/36) → pin the exact version there"
  ! [[ "$output" == *"shiv:shimmer 0.5.0 is a range"* ]]
  ! [[ "$output" == *"every shiv: pin is exact"* ]]
  printf '[tools]\n"shiv:notes" = "0.5.0"\n' > "$global"
  doctor_with SHIV_SOURCES_DIR="$src" MISE_GLOBAL_CONFIG_FILE="$global"
  assert_success
  ! [[ "$output" == *"is a range"* ]]
  assert_output_contains "ok:   $global: every shiv: pin is exact"
  printf '[tools]\njq = "latest"\n' > "$global"
  doctor_with SHIV_SOURCES_DIR="$src" MISE_GLOBAL_CONFIG_FILE="$global"
  assert_success
  ! [[ "$output" == *"$global"* ]]
  H="$BATS_TEST_TMPDIR/hearth"
  printf '[tools]\n"shiv:notes" = "latest"\n' > "$global"
  doctor_with MISE_GLOBAL_CONFIG_FILE="$global"
  assert_success
  ! [[ "$output" == *"is a range"* ]]
}
