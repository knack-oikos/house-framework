**Notes are encrypted here** with git-crypt, through
[KnickKnackLabs/notes](https://github.com/KnickKnackLabs/notes): on GitHub
they are encrypted blobs with obfuscated names; locally they are readable
after `notes unlock`. `house init --with notes` declared the package. The
owner switches encryption on, in their own turn, with `{{NOTES_SETUP}}`;
`house doctor` fails until that has run.

- Edit notes under their readable names. `notes changes` shows what you
  touched; `git status` does not.
- Stage and commit a note only with `notes commit -m '<message>'
  notes/<file>.md`. `git add notes/<name>` stages nothing useful, and a
  commit that adds a note by its obfuscated name bypasses the tool and is
  the owner's to make, never an agent's.
- Encryption is not a licence for secrets: write nothing a collaborator
  holding the key should not read.
