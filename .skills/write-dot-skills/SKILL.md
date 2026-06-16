---
name: write-dot-skills
description: Helps with writing, creating, adding, drafting, updating, reviewing, renaming, cleaning up, or removing dotfiles-managed shared user skills in home/dot_skills or ~/.skills for Claude Code and Codex; triggers include dot_skills, dot skills, write skill, create skill, skill authoring, user/shared skill, SKILL.md, Claude/Codex skills, 스킬 작성, 스킬 생성, 스킬 만들기, 스킬 추가, 스킬 수정, 스킬 검토, 스킬 정리, 스킬 삭제, 사용자/공유 스킬, 닷스킬, dotfiles 스킬.
---

# Write Dot Skills

## Process

1. **Gather requirements** - ask only when the request is ambiguous:
    - Shared user skill in `home/dot_skills`, or project skill in `.skills`?
    - What recurring task or domain should the skill cover?
    - Which English/Korean phrases, paths, or files should trigger it?
    - Instructions only, or deterministic scripts/references too?
    - Should docs, tests, install scripts, or cleanup paths change?

2. **Draft the skill** - create or update:
    - Shared user skill: `home/dot_skills/<skill-name>/SKILL.md`.
    - Project-local skill: `.skills/<skill-name>/SKILL.md`.
    - References only when `SKILL.md` would become too long.
    - Scripts only when generation, validation, or formatting must be deterministic.

3. **Review and verify**:
    - Ask the user about missing use cases only when judgment is required.
    - Run focused checks first; run the full gate when managed files, docs, tests,
      or scripts changed.

## Dotfiles Paths

`home/dot_skills` is the chezmoi source for shared user skills. It deploys to
`~/.skills`, and both Claude Code and Codex consume that directory through
symlinks:

```text
~/.claude/skills -> ~/.skills
~/.agents/skills -> ~/.skills
```

Do not add shared user skills directly under `~/.skills`, `.claude/skills`,
or `.agents/skills` in this repository. Those are deployed targets or symlink
targets.

## SKILL.md Template

Use the normal shape: YAML frontmatter with `name` and `description`, then a
short body with `Process`, project-specific rules, and exact verification.

## Description Requirements

The description is the main signal agents use to decide whether to load a
skill. Keep it under 1024 characters, write in third person, and include:

- Specific English and Korean trigger words.
- Relevant paths such as `home/dot_skills`, `~/.skills`, or `SKILL.md`.
- Claude Code and Codex when the skill should apply to both.

## Chezmoi, Docs, And Tests

Update docs when deployment behavior, shared topology, install flow, operations,
or test expectations change: `docs/01-overview.md`, `docs/02-architecture.md`,
`docs/03-installation.md`, `docs/05-ai-tools.md`, `docs/06-operations.md`,
`docs/07-testing.md`.

Update tests when behavior changes: `tests/skills-migrate.sh` for cleanup or
symlink migration, `tests/mattpocock-skills-sync.sh` for mattpocock sync, and
`tests/macos.sh`/`tests/linux.sh` for managed paths or platform checks.

For removed or renamed managed skills, consider `home/.chezmoiremove` for stale
deployed paths. Do not invent metadata such as `is_removed` unless project code
already consumes it.

## Verification

```bash
git diff --check
bash tests/skills-migrate.sh home/.chezmoiscripts/run_once_before_00-skills-ssot-migrate.sh.tmpl
# If mattpocock sync changed:
bash tests/mattpocock-skills-sync.sh home/dot_local/bin/executable_mattpocock-skills-sync
# If chezmoi-managed files, docs, tests, or scripts changed:
DOCKER_CONFIG=/private/tmp/dotfiles-docker-config make check
```

## Review Checklist

- [ ] `name` matches the skill directory and uses lowercase hyphen-case.
- [ ] `description` includes concrete English/Korean triggers.
- [ ] `SKILL.md` stays concise; split rare details into one-level references.
- [ ] Shared user skills live under `home/dot_skills`, not tool-specific targets.
- [ ] Claude Code and Codex shared-skill paths are both considered.
- [ ] Docs/tests were updated, or intentionally left unchanged with a reason.
- [ ] Relevant checks passed.
- [ ] No commit or push was made unless the user explicitly asked.
