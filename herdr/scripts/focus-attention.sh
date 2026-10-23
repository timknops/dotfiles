#!/bin/sh
# Focus the agent that most needs attention: blocked first, then done.
# Within a state, the one that has been waiting longest wins. The focused
# agent is skipped, so pressing the key again moves on to the next one.
herdr="${HERDR_BIN_PATH:-herdr}"

target=$("$herdr" agent list | jq -r '
  [.result.agents[]
   | select(.focused | not)
   | select(.agent_status == "blocked" or .agent_status == "done")]
  | sort_by((if .agent_status == "blocked" then 0 else 1 end), .state_change_seq)
  | first | .pane_id // empty')

[ -n "$target" ] && "$herdr" agent focus "$target"
exit 0
