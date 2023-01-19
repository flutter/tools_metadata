#!/bin/bash

BOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$BOTDIR/.."

./bots/run.sh

# Check for git changes in the resources folder, but excluding
# version.json which will change on every beta regardless of actual
# functional changes.
changes=$(git status --porcelain resources | grep -v version.json)

if [[ $changes ]]; then
  echo "Resources contain changes that do not match last committed version."
  echo ""
  echo "Please run bots/run.sh locally and commit the changes."
  echo ""
  echo "$changes"
  exit 1
else
  echo "No git changes, everything is up to date!"
  exit 0
fi
