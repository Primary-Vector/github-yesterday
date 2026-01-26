# github-yesterday

A simple CLI tool that shows all your GitHub PRs updated yesterday. On Mondays, it automatically pulls Friday's activity instead (because who cares about Sunday).

## Requirements

- [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated
- `jq` for JSON parsing

## Usage

```bash
./github-yesterday.sh
```

That's it. No flags, no config. Just run it and see what you worked on yesterday.

## Output

PRs are displayed with status emojis and shortened URLs:

```
:pr-merged: Fix login bug (myorg/myrepo/pull/123)
:pr-open: Add new feature (myorg/myrepo/pull/456)
:pr-closed: Abandoned experiment (myorg/myrepo/pull/789)
```

## Installation

```bash
git clone https://github.com/Primary-Vector/github-yesterday.git
cd github-yesterday
chmod +x github-yesterday.sh

# Optionally add to your PATH or create an alias
alias ghy='~/path/to/github-yesterday.sh'
```
