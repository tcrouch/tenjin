---
name: commit-conventions
description: Use when writing a commit message, PR title, or PR description in this repo. Carries the Conventional Commits prefix table, subject and body rules, the squash-merge PR-title rule, and the PR description format.
---

## Commits and pull requests

### Commit messages

- **Subject**: follow Conventional Commits: `<type>(<scope>)?: <summary>`. A type prefix, then a summary beginning with an imperative verb; no trailing full stop. Aim for 50 characters including the prefix; never exceed 70. It reads as what this commit does to the codebase, not what happened.

```
Bad:  fix: fixed the stale run line showing 0 unfinished
Good: fix: give stale runs the outcome line of complete ones
```

- **Structure**: one line for simple changes. Complex changes add a body after one blank line.
- **Body**: up to three sentences covering *what* the commit includes, and *why* where that is not obvious from the change. Prose, present tense, wrapped at 72. Reserve depth for the PR description: mechanism, alternatives, and anything the reader needs only once. Never a status report: test/lint results, measured impact, or review and process provenance; those belong in the PR too. Each sentence's subject is the change, not the work of making or checking it.

```
Bad:  Checked that no workflow ever resumes a group sync
Bad:  No workflow ever resumes a group sync
      (the same report with the checking removed)
Good: The live line says "failed" rather than "awaiting retry", which
      no workflow promises a group sync
```

#### Subject prefixes

The Conventional Commits spec mandates only `feat` and `fix`; the rest is this repo's vocabulary — Angular's set plus `ops`. Choose the type by the question the change answers, not by the files it touches:

| Type | Question it answers | Typical here |
|---|---|---|
| `feat` | Does a user gain or lose behaviour? | New page, field, or admin workflow |
| `fix` | Was user-visible behaviour wrong? | A bug in a feature |
| `refactor` | Same behaviour, different structure? | Extract a service, rename a component |
| `perf` | Same behaviour, faster? | Query or caching change |
| `test` | Only specs changed? | New or corrected specs |
| `docs` | Only documentation? | README, `CLAUDE.md`, `.claude/` skills |
| `style` | Only formatting? | rubocop or prettier autocorrect |
| `build` | What is the app made of, or with? | Ruby/Node versions, gems, npm packages, the package manager, Shakapacker/webpack config, Bundler |
| `ops` | Where and how does it run? | Heroku stack, buildpacks, `Procfile`, dyno/Puma/Sidekiq concurrency, config vars, HireFire, monitoring |
| `ci` | How is it checked? | `.github/workflows` |
| `chore` | Nothing above fits | `.gitignore`, editor config, lint config |
| `revert` | Undoes an earlier commit | `revert: <original subject>` |

- **The type follows the primary change**, not every file touched: migrating to a different JS package manager is `build:` even though it edits workflows.
- **Upgrade streams share a type and scope** so the whole stream is one grep: `build(rails): upgrade to 7.1`, then `build(rails): enable the 7.1 cache format` for the framework-default flips the upgrade requires. A dependency bump is `build`; standalone tuning of the same component is `ops` — `build: upgrade puma to 7` versus `ops: run one puma worker`.
- **`chore` is a last resort**, not a default. If a commit could be `build`, `ops`, `ci` or `docs`, it is.

### Pull request titles

The repository squash-merges, and GitHub seeds the squash commit message from the **PR title** — the commit subject on the branch is discarded. A PR title is therefore a commit subject, held to the same rules above: a Conventional Commits prefix, an imperative verb, 50 characters and never more than 70. For a single-commit branch, pass that commit's subject verbatim; for several, write one that describes the merged result.

```
Bad:  Group dashboard counts into thousands
Good: feat: group dashboard counts into thousands
```

Getting it wrong lands an unprefixed subject on `main`, and the only fix is a force-push over a ruleset that forbids one.

### Pull Request Descriptions

- **Describe the merged result, not the branch**: what the code now does and why. Intermediate states are in the git log; a reviewer reads the diff.
- **No boilerplate headings**: the title and first paragraph are the summary. Headings only when the body is long enough to need navigating.
- **Rationale sits beside what it justifies**: a bullet per behaviour, its reason in the same bullet. A separate "why not X" only where a reviewer would plausibly ask, and X is an alternative to the shipped design, never an earlier commit on the branch.
- **Close with what the commit body may not carry**: test coverage and results, review or process provenance, measured impact. A line each, saying what was verified rather than how much: a findings count or a test total gives the reviewer nothing to act on.
- **Paragraphs flow**: one line per paragraph, no hard wraps. GitHub soft-wraps, and `gt submit` copies the commit message in verbatim, so a 72-column body renders raggedly until rewritten with `gh pr edit --body-file`.

```
Bad:  ## Alternatives
      The first commit put log_file_size in the defaults file; the second moves it.
Good: `log_file_size` sits in `application.rb` rather than the defaults file:
      bootstrap builds the logger before initializers load, so the template's
      placement never takes effect.

Bad:  twenty flags flipped; 726 examples, 0 failures
Good: config dump diffed before and after in development and test: every flag
      moves its runtime attribute; `bin/parallel_specs` passes, system phase included
```
