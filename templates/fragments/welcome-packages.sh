echo ""
echo "== packages =="
while IFS=$'\t' read -r pkg version; do
  if mise where "shiv:$pkg@$version" >/dev/null 2>&1; then
    echo "$pkg $version: installed"
  else
    echo "$pkg $version: missing → mise install"
  fi
done < <(sed -n 's/^"shiv:\([^"]*\)" = "\([^"]*\)".*$/\1\t\2/p' "$HOUSE_DIR/mise.toml")
