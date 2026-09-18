load test_helper

@test "the shim's surface is init, doctor, version and agent add; test is hidden" {
  run bash -c "cd '$REPO_DIR' && mise tasks ls --json --hidden | jq -r 'sort_by(.name)[] | \"\\(.name) \\(.hide)\"'"
  assert_success
  [ "$output" = "agent:add false
doctor false
init false
test true
version false" ]
  run bash -c "cd '$REPO_DIR' && mise tasks ls --json | jq -r '.[].name'"
  ! [[ "$output" == *"test"* ]]
}
