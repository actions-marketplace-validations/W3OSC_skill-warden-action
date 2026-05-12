#!/usr/bin/env bash
# skill-warden-action entrypoint
# This script is used when running as a Docker-based action.

set -euo pipefail

TARGET="${INPUT_TARGET:-}"
OUTPUT_FORMAT="${INPUT_OUTPUT_FORMAT:-sarif}"
SARIF_FILE="${INPUT_SARIF_FILE:-skill-warden-results.sarif}"
FAIL_ON_ADVISORY="${INPUT_FAIL_ON_ADVISORY:-false}"
GITHUB_TOKEN_INPUT="${INPUT_GITHUB_TOKEN:-}"
NO_QUALITY="${INPUT_NO_QUALITY:-false}"
NO_AI_SCORE="${INPUT_NO_AI_SCORE:-false}"

if [ -z "$TARGET" ]; then
  echo "ERROR: 'target' input is required." >&2
  exit 1
fi

# Install skill-warden if not already installed
if ! command -v skill-warden &> /dev/null; then
  pip install skill-warden --quiet
fi

# Build arguments
ARGS=()
ARGS+=(scan "$TARGET")
ARGS+=(--output sarif --output-file "$SARIF_FILE")

if [ -n "$GITHUB_TOKEN_INPUT" ]; then
  ARGS+=(--github-token "$GITHUB_TOKEN_INPUT")
fi

if [ "$FAIL_ON_ADVISORY" = "true" ]; then
  ARGS+=(--fail-on-advisory)
fi

if [ "$NO_QUALITY" = "true" ]; then
  ARGS+=(--no-quality)
fi

if [ "$NO_AI_SCORE" = "true" ]; then
  ARGS+=(--no-ai-score)
fi

echo "::group::skill-warden scan"
EXIT_CODE=0
skill-warden "${ARGS[@]}" || EXIT_CODE=$?
echo "::endgroup::"

# Print pretty summary to log
echo "::group::skill-warden summary"
skill-warden scan "$TARGET" \
  --output pretty \
  ${GITHUB_TOKEN_INPUT:+--github-token "$GITHUB_TOKEN_INPUT"} \
  --no-quality --no-ai-score 2>/dev/null || true
echo "::endgroup::"

# Set outputs for composite action
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  if [ $EXIT_CODE -eq 0 ]; then
    echo "hard-passed=true" >> "$GITHUB_OUTPUT"
    echo "has-advisories=false" >> "$GITHUB_OUTPUT"
  elif [ $EXIT_CODE -eq 2 ]; then
    echo "hard-passed=true" >> "$GITHUB_OUTPUT"
    echo "has-advisories=true" >> "$GITHUB_OUTPUT"
  else
    echo "hard-passed=false" >> "$GITHUB_OUTPUT"
    echo "has-advisories=true" >> "$GITHUB_OUTPUT"
  fi
fi

exit $EXIT_CODE
