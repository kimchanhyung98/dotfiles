---
name: sample
description: Example user-level skill shared across Claude Code and Codex through ~/.skills symlinks.
---

# Sample Skill

This file shows the expected shape of a skill placed in `~/.skills`, the single
source of truth for user-level skills.

Claude Code and Codex reach this directory through a
`skills -> ../.skills` symlink, so dropping a real skill here makes it available
to both tools at once. Keep one skill per directory, each with its own
`SKILL.md`.
