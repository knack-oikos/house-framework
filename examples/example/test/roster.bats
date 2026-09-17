setup() {
  HOUSE="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

@test "every agent on the roster has an identity note" {
  while IFS= read -r name; do
    [ -f "$HOUSE/notes/$name.md" ]
  done < <(awk -F '\t' '!/^#/ && NF { print $1 }' "$HOUSE/roster.tsv")
}

@test "every agent on the roster is listed under Who lives here" {
  while IFS= read -r name; do
    grep -q "^- \*\*$name\*\* — " "$HOUSE/AGENTS.md"
  done < <(awk -F '\t' '!/^#/ && NF { print $1 }' "$HOUSE/roster.tsv")
}

@test "the contract keeps its markers and its authority sections" {
  for marker in "<!-- house:roster -->" "<!-- house:rules -->" "<!-- house:read-first -->"; do
    grep -qxF "$marker" "$HOUSE/AGENTS.md"
  done
  grep -qxF "### The tiers — canonical list" "$HOUSE/AGENTS.md"
  grep -qxF "### The loosenings — canonical list" "$HOUSE/AGENTS.md"
  grep -qxF "#### The two-key rule" "$HOUSE/AGENTS.md"
}

@test "the roster has at most one housekeeper and it is named housekeeper" {
  keepers="$(awk -F '\t' '!/^#/ && $4 == "housekeeper" { print $1 }' "$HOUSE/roster.tsv")"
  [ "$(printf '%s' "$keepers" | grep -c .)" -le 1 ]
  [ -z "$keepers" ] || [ "$keepers" = housekeeper ]
}
