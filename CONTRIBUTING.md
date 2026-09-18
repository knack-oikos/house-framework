# Contributing

house-framework is a small tool with a strict shape, so a change lands more
easily when it is discussed before it is written.

1. **Open an issue first.** Say what you would change and why. A template
   change alters what agents in every future house may do, and a maintainer
   may say no before you spend the time.
2. **Branch in your fork and open a pull request into `main`.** One idea per
   pull request.
3. **Run the gates before you push**, the same two CI runs:

   ```bash
   mise run test
   git diff --check
   ```

   After a change under `templates/`, run `mise run examples --write` and
   commit `examples/` in the same change; the test task fails on drift.
4. **Commit messages are conventional** — `feat:`, `fix:`, `docs:`, `test:`,
   `refactor:` — with no footers and no tool attribution.
5. **Read [`AGENTS.md`](AGENTS.md).** It is the contract for this repository
   for anyone's agent, and it lists what a change must preserve.

Nothing here asks you to belong to a house, to know where a rule came from,
or to run any particular agent harness.
