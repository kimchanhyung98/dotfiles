---
name: sample
description: Example user-level skill shared across every AI CLI through ~/.skills symlinks.
---

# Sample Skill

This file shows the expected shape of a skill placed in `~/.skills`, the single
source of truth for user-level skills.

Each AI CLI (Claude, Codex, agents, Copilot) reaches this directory through a
`skills -> ../.skills` symlink, so dropping a real skill here makes it available
to all of them at once. Keep one skill per directory, each with its own
`SKILL.md`.
