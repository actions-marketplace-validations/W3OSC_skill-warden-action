# skill-warden-action

> GitHub Action for [skill-warden](https://github.com/W3OSC/skill-warden) - security scanner for AI skills.

[![skill-warden](https://img.shields.io/badge/powered%20by-skill--warden-blueviolet?style=flat-square)](https://github.com/W3OSC/skill-warden)
[![W3OSC](https://img.shields.io/badge/W3OSC-initiative-purple?style=flat-square)](https://github.com/W3OSC)

## Overview

`skill-warden-action` runs the `skill-warden` security scanner in your GitHub Actions workflow. It detects prompt injection, jailbreak attempts, secret grabbing, token smuggling, and more in AI skill repositories - and uploads results directly to the GitHub Security tab via SARIF.

## Usage

### Basic scan

```yaml
name: Skill Security Scan

on:
  push:
    branches: [main]
  pull_request:

jobs:
  scan:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      - uses: W3OSC/skill-warden-action@v1
        with:
          target: ${{ github.repository }}
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

### Scan a specific skill path

```yaml
      - uses: W3OSC/skill-warden-action@v1
        with:
          target: https://github.com/owner/repo/tree/main/skills/my-skill
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

### Enforce advisory checks and local path

```yaml
      - uses: W3OSC/skill-warden-action@v1
        with:
          target: ./skills/
          fail-on-advisory: 'true'
          upload-sarif: 'false'
```

## Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `target` | GitHub URL, `owner/repo`, or local path to scan | **required** |
| `output-format` | Output format: `pretty`, `json`, or `sarif` | `sarif` |
| `sarif-file` | Path for SARIF output file | `skill-warden-results.sarif` |
| `fail-on-advisory` | Exit code 2 (fail) if advisory violations found | `false` |
| `github-token` | Token for private repos | `${{ github.token }}` |
| `upload-sarif` | Upload SARIF to GitHub Security tab | `true` |
| `no-quality` | Skip quality checks | `false` |
| `no-ai-score` | Skip AI slop scoring | `false` |

## Outputs

| Output | Description |
|--------|-------------|
| `hard-passed` | `true` if all hard security checks passed |
| `has-advisories` | `true` if any advisory violations were found |
| `sarif-file` | Path to the generated SARIF file |

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All hard security checks passed |
| `1` | Hard security violation(s) found - skill is unsafe |
| `2` | Advisory violations found (only with `fail-on-advisory: true`) |

## Using outputs

```yaml
      - id: warden
        uses: W3OSC/skill-warden-action@v1
        with:
          target: ${{ github.repository }}

      - name: Check results
        run: |
          echo "Hard passed: ${{ steps.warden.outputs.hard-passed }}"
          echo "Has advisories: ${{ steps.warden.outputs.has-advisories }}"

      - name: Block merge if unsafe
        if: steps.warden.outputs.hard-passed == 'false'
        run: |
          echo "::error::skill-warden detected security violations. Blocking merge."
          exit 1
```

## Detection Summary

| Detector | Severity | Type |
|----------|----------|------|
| Prompt Injection | Critical | Hard fail |
| Jailbreak | Critical | Hard fail |
| Token Smuggling | High | Hard fail |
| Secret Grabbing | High | Advisory |
| External Fetch Coercion | Medium | Advisory |
| Content Obfuscation | Medium | Advisory |
| Description Correctness | Info | Quality |
| SKILL.md Length | Info | Quality |
| Nested References | Info | Quality |
| Large Reference Without TOC | Info | Quality |

## Requirements

- The action installs `skill-warden` via `pip` on each run
- Python 3.10+ must be available (standard on `ubuntu-latest`)
- For SARIF upload, the job needs `security-events: write` permission

---

<div align="center">
  <sub>Part of the <a href="https://github.com/W3OSC">W3OSC</a> security toolchain</sub>
</div>
