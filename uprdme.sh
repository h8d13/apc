#!/bin/bash
# Regenerate the "## Usage:" section of readme.md from `aptac --help`.
set -euo pipefail

cd "$(dirname "$0")"

README="readme.md"
MARKER="## Usage:"

# strip leading/trailing blank lines so the fence hugs the content
help_out="$(./aptac --no-color --help | sed -e '/./,$!d' -e :a -e '/^\n*$/{$d;N;ba}')"

# Keep everything up to and including the marker line, drop the rest.
head_part="$(sed "/^${MARKER}\$/q" "$README")"

{
  printf '%s\n\n' "$head_part"
  printf '```\n%s\n```\n' "$help_out"
} > "$README.tmp"

mv "$README.tmp" "$README"
echo "updated $README"
