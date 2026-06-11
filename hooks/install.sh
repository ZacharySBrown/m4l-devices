#!/usr/bin/env bash
# Point git's hooks to the committed hooks/ directory.
cd "$(dirname "$0")/.."
git config core.hooksPath hooks
chmod +x hooks/pre-commit
echo "✓ git hooks now point to hooks/ (pre-commit active)"
