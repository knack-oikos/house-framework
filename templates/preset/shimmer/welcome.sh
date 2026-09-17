agents="$(mise run -q agent:list | tr '\n' ' ')"
echo "agent:list: ${agents:-nobody yet; the housekeeper is excluded by design}"
