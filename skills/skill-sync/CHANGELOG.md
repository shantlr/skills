# Changelog

All notable changes to the `skill-sync` skill are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning is [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-09-13

### Added

- Release workflow: pick a semver bump, update `SKILL.md` frontmatter, prepend a
  `CHANGELOG.md` entry, and refresh the README row in one commit.
- Update workflow: compare `~/.claude/skills` against the repo, report
  outdated / linked / external / drifted skills, and apply after showing the
  changelog entries the user would be pulling in.
- `scripts/status.sh` for the installed-vs-repo comparison.
- `assets/CHANGELOG.template.md` for new skills.
