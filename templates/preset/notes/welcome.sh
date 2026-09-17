if grep -F "{{NOTES_REL}}/**" "$WORK_DIR/.gitattributes" 2>/dev/null | grep -q 'filter=git-crypt' && [ -d "$WORK_DIR/.git-crypt/keys/default" ]; then
  echo "{{NOTES_REL}}/: encrypted (git-crypt)"
else
  echo "{{NOTES_REL}}/: plaintext → {{NOTES_SETUP}}"
fi
