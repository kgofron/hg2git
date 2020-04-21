#!/bin/bash

# Author: K. Gofron
# Date: 2020-2-12
# Source: https://github.com/kgofron/hg2git.git

# EXAMPLE
# hgCloseBranch.sh srx

BRANCH=$1       # Hg feature branch to close
echo "Closing hg $BRANCH, and mergin with default"

hg up $BRANCH
hg ci -m 'Closed branch $BRANCH' --close-branch
hg up default
hg merge $BRANCH
hg ci -m merge
echo "Merged hg $BRANCH, into default"
