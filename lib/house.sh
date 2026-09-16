#!/usr/bin/env bash

HOUSE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOUSE_REPO_DIR="$(cd "$HOUSE_LIB_DIR/.." && pwd)"
HOUSE_TEMPLATES="$HOUSE_REPO_DIR/templates"

say() { printf '%s\n' "$*"; }
err() { printf 'Error: %s\n' "$*" >&2; }
die() { err "$@"; exit 1; }

validate_name() {
  local what="$1" value="$2"
  [ -n "$value" ] || die "$what is required"
  case "$value" in
    *[!a-z0-9-]* | -* | *-) die "$what must use lowercase letters, digits, and internal hyphens only: $value" ;;
  esac
}

upper_env() {
  printf '%s' "$1" | tr '[:lower:]-' '[:upper:]_'
}

caller_pwd() {
  printf '%s' "${HOUSE_CALLER_PWD:-${HOUSE_FRAMEWORK_CALLER_PWD:-${CALLER_PWD:-$PWD}}}"
}

resolve_path() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *)  printf '%s/%s\n' "$(caller_pwd)" "$1" ;;
  esac
}

canonical_path() {
  local p="$1"
  mkdir -p "$p"
  (cd "$p" && pwd -P)
}

display_path() {
  case "$1" in
    "$HOME"/*) printf '~%s\n' "${1#"$HOME"}" ;;
    "$HOME")   printf '~\n' ;;
    *)         printf '%s\n' "$1" ;;
  esac
}

render() {
  local src="$1" dest="$2"
  shift 2
  local content key value
  content="$(cat "$src"; printf x)"
  content="${content%x}"
  for kv in "$@"; do
    key="${kv%%=*}"
    value="${kv#*=}"
    content="${content//"{{$key}}"/$value}"
  done
  mkdir -p "$(dirname "$dest")"
  printf '%s' "$content" > "$dest"
}

render_string() {
  local content="$1"
  shift
  local key value
  for kv in "$@"; do
    key="${kv%%=*}"
    value="${kv#*=}"
    content="${content//"{{$key}}"/$value}"
  done
  printf '%s' "$content"
}

install_tree() {
  local src_root="$1" dest_root="$2"
  shift 2
  local src rel dest
  while IFS= read -r src; do
    rel="${src#"$src_root"/}"
    case "$rel" in
      *.tmpl) dest="$dest_root/${rel%.tmpl}" ;;
      *)      dest="$dest_root/$rel" ;;
    esac
    if [ -e "$dest" ]; then
      say "keep: ${dest#"$dest_root"/}"
      continue
    fi
    render "$src" "$dest" "$@"
    case "${dest#"$dest_root"/}" in
      .mise/tasks/*|hooks/*) chmod +x "$dest" ;;
    esac
    say "create: ${dest#"$dest_root"/}"
  done < <(find "$src_root" -type f | sort)
}

house_root() {
  local candidate
  candidate="$(resolve_path "${1:-.}")"
  candidate="$(cd "$candidate" 2>/dev/null && pwd -P)" || die "not a directory: $1"
  [ -f "$candidate/roster.tsv" ] && [ -f "$candidate/AGENTS.md" ] \
    || die "not a house (no roster.tsv and AGENTS.md): $candidate"
  printf '%s\n' "$candidate"
}

house_name() {
  basename "$1"
}

house_project() {
  sed -n 's/^HOUSE_PROJECT = "\(.*\)"$/\1/p' "$1/mise.toml" | head -1
}

house_work_dir() {
  local house="$1" top
  top="$(git -C "$house" rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -n "$top" ] && [ "$top" != "$house" ]; then
    printf '%s\n' "$top"
  else
    printf '%s\n' "$house"
  fi
}

roster_agents() {
  awk -F '\t' '!/^#/ && NF { print $1 }' "$1/roster.tsv"
}

roster_has() {
  awk -F '\t' -v n="$2" '!/^#/ && $1 == n { found = 1 } END { exit !found }' "$1/roster.tsv"
}

roster_append() {
  local house="$1" name="$2" role="$3" owns="$4"
  printf '%s\t%s\t%s\n' "$name" "$role" "$owns" >> "$house/roster.tsv"
}

insert_before_marker() {
  local file="$1" marker="$2" text="$3"
  local tmp line found=0
  grep -qxF "$marker" "$file" || die "marker missing in $file: $marker"
  tmp="$(mktemp)"
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$line" = "$marker" ] && [ "$found" -eq 0 ]; then
      printf '%s\n' "$text"
      found=1
    fi
    printf '%s\n' "$line"
  done < "$file" > "$tmp"
  mv "$tmp" "$file"
}

today() {
  date +%Y-%m-%d
}

agent_kind_tools() {
  case "$1" in
    builder)     printf 'Read, Grep, Glob, Bash, Edit, Write' ;;
    judge)       printf 'Read, Grep, Glob, Bash, WebFetch, WebSearch' ;;
    housekeeper) printf 'Read, Grep, Glob, Bash, Edit, Write' ;;
  esac
}

capitalize() {
  printf '%s' "$1" | sed 's/^./\U&/'
}

add_agent() {
  local house="$1" name="$2" role="$3" owns="$4" charge="$5" tools="$6" kind="$7" no_home="$8" no_definition="$9"
  local house_name house_upper project work agents_root definitions_dir description roster_line
  local home_dir def

  validate_name "agent name" "$name"
  if roster_has "$house" "$name"; then
    die "$name is already on the roster of $(display_path "$house")"
  fi
  case "$kind" in builder|judge|housekeeper) ;; *) die "unknown agent kind: $kind" ;; esac
  if [ "$kind" = builder ] && [ -z "$owns" ]; then die "a builder must --owns a directory"; fi
  if [ "$kind" != builder ] && [ -n "$owns" ]; then die "a $kind owns no directory; drop --owns"; fi

  house_name="$(house_name "$house")"
  house_upper="$(upper_env "$house_name")"
  project="$(house_project "$house")"
  project="${project:-$house_name}"
  work="$(house_work_dir "$house")"
  agents_root="${HOUSE_AGENTS_ROOT:-$HOME/agents}"
  definitions_dir="${HOUSE_DEFINITIONS_DIR:-$HOME/.claude/agents}"
  tools="${tools:-$(agent_kind_tools "$kind")}"

  case "$kind" in
    builder)
      owns="${owns%/}/"
      charge="${charge:-Builds and maintains everything under \`$owns\`.}"
      roster_line="- **$name** — $role. Owns \`$owns\`: $charge"
      description="$(capitalize "$role") for the $house_name household of $project — takes the top queued entry addressed to it, implements it under $(display_path "$work")/$owns on a $name/<topic> branch with tests, runs the gates, and opens a pull request into main. Use for anything about $(display_path "$work")/$owns."
      ;;
    judge)
      charge="${charge:-Produces judgement the owner acts on, never patches.}"
      roster_line="- **$name** — $role. Owns no directory. $charge"
      description="$(capitalize "$role") for the $house_name household of $project — takes the top queued entry addressed to it and answers it in the written record: findings with locations, rankings with reasons, verdicts with the evidence attached. Judgement only — never patches, never merges. Use for anything that needs an opinion rather than a change."
      ;;
    housekeeper)
      local default_charge="Keeps the household's written record true: the queue, the backlog, the notes, the branches, and this contract against what is actually on disk. No GitHub identity and no mail, by design."
      charge="${charge:-$default_charge}"
      roster_line="- **$name** — $role. Owns no directory. $charge"
      description="Housekeeper of the $house_name household of $project — standing work that needs no filing: audits the work queue, the backlog, the notes, the roster and the branches against what is actually on disk, fixes verified-false facts in notes/ on a local $name/<topic> branch, files everything else for the owner, and reports what needs the owner. Carries no GitHub identity, no signing key and no mail, permanently. Use for 'is the record true', 'what is stale', 'what is unmerged or unpushed', or 'tidy the queue'."
      ;;
  esac

  local vars=(
    "AGENT=$name"
    "ROLE=$role"
    "OWNS=$owns"
    "CHARGE=$charge"
    "TOOLS=$tools"
    "DESCRIPTION=$description"
    "HOUSE_NAME=$house_name"
    "HOUSE_UPPER=$house_upper"
    "HOUSE_PATH=$(display_path "$house")"
    "WORK_PATH=$(display_path "$work")"
    "PROJECT=$project"
    "AGENTS_ROOT=$(display_path "$agents_root")"
    "CREATED=$(today)"
  )

  roster_append "$house" "$name" "$role" "$owns"
  say "roster: $name ($kind)"

  render "$HOUSE_TEMPLATES/agent/note.$kind.md.tmpl" "$house/notes/$name.md" "${vars[@]}"
  say "create: notes/$name.md"

  insert_before_marker "$house/AGENTS.md" "<!-- house:roster -->" "$roster_line"
  insert_before_marker "$house/AGENTS.md" "<!-- house:read-first -->" \
    "| act as $name for the first time in a session | [\`notes/$name.md\`](notes/$name.md) |"
  say "update: AGENTS.md (roster, read-first)"

  if [ "$no_home" != "true" ]; then
    home_dir="$agents_root/$name/home"
    if [ -e "$home_dir/AGENTS.md" ]; then
      say "keep: $(display_path "$home_dir") already has an AGENTS.md"
    else
      mkdir -p "$home_dir"
      render "$HOUSE_TEMPLATES/agent/home/AGENTS.$kind.md.tmpl" "$home_dir/AGENTS.md" "${vars[@]}"
      render "$HOUSE_TEMPLATES/agent/home/mise.toml.tmpl" "$home_dir/mise.toml" "${vars[@]}"
      render "$HOUSE_TEMPLATES/agent/home/SCRATCHPAD.md.tmpl" "$home_dir/SCRATCHPAD.md" "${vars[@]}"
      [ -d "$home_dir/.git" ] || git -C "$home_dir" init -q -b main
      say "create: $(display_path "$home_dir") (AGENTS.md, mise.toml, SCRATCHPAD.md; local repo, no remote)"
    fi
  fi

  if [ "$no_definition" != "true" ]; then
    def="$definitions_dir/$name.md"
    if [ -e "$def" ]; then
      say "keep: $(display_path "$def") exists"
    else
      render "$HOUSE_TEMPLATES/agent/definition.$kind.md.tmpl" "$def" "${vars[@]}"
      say "create: $(display_path "$def")"
    fi
  fi
}
