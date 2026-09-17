if grep -F "{{NOTES_REL}}/**" "$WORK_DIR/.gitattributes" 2>/dev/null | grep -q 'filter=git-crypt'; then
  echo "{{NOTES_REL}}/: encrypted (git-crypt)"
else
  echo "{{NOTES_REL}}/: plaintext → {{NOTES_SETUP}}"
fi
