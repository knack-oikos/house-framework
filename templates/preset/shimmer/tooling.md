- **shimmer** — `shiv:shimmer`, declared by `house init --with shimmer`.
  `mise run agent:list` feeds it the roster minus the housekeeper, which is
  what its dispatch and CI tasks read. It is not the identity path:
  `shimmer as` reads a token through `secrets` and a desktop keyring, and
  this house depends on neither — identity stays `agent-env`, and per-agent
  accounts stay the backlog entry.
  When a session it woke from CI is fundamentally blocked, it says so with
  `[[ABORT]]` on its own line and stops; that is shimmer's convention, and
  shimmer reads it.
