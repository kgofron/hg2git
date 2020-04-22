#!/bin/bash

# Author: K. Gofron
# Date: 2020-4-21
# Source: https://github.com/kgofron/hg2git.git
# The .hgrc with 'username' set must esits in home directory

# EXAMPLE
# hgCloseBranch.sh -b srx -u softioc
# hgCloseBranch.sh -b srx -u softioc -cb chx    # merge srx, and close chx

BRANCH=""       # Hg feature branch to merge and then close
CL_BRANCH=""    # Hg feature branch to close (NOT merged)
IOC_OWNER=""    # owner of the iocs folder (softioc)
BRANCHES=""     # Branches list

USAGE="[-b <branch>] [-u <user>]"
LONG_USAGE="Merge hg repository <repo> feature branch with default branch, and close feature branch.

Note: The argument order matters.
Options:
	-b <branch>   Mercurial repository branch to merge to default and close
	-u <user>     IOC Owner account (e.g. softioc)
  -cb <close>   Mercurial repository branch to close (NOT merged into default)
"
case "$1" in
    -h|--help)
      echo "usage: $(basename "$0") $USAGE"
      echo ""
      echo "$LONG_USAGE"
      exit 0
esac

while case "$#" in 0) break ;; esac
do
  case "$1" in
    -b|--branch)
      shift
      BRANCH="$1"
      echo "Branch=$BRANCH"
      ;;
    -u|--usr|--user)
      # Owner of the ioc directory
      shift
      IOC_OWNER="$1"
      echo "IOC owner=$IOC_OWNER"
      ;;
    -cb|--cBranch)
      shift
      CL_BRANCH="$1"
      echo "CloseBranch=$CL_BRANCH"
      ;;      
  esac
  shift
done

BRANCHES=`hg branches | awk '{ print $1 }'`
echo "Branches->$BRANCHES"
# if [[ $BRANCHES == *$BRANCH* ]] && [[ ! "$BRANCH" = "" ]]; then
#   echo "$BRANCH is there"
# fi
# if [[ $BRANCHES == *$CL_BRANCH* ]]; then
#   echo "$CL_BRANCH is there"
# fi
# if [[ $BRANCHES == *$CL_BRANCH* ]]; then
#   echo "$CL_BRANCH is there"
#   else
#   echo "$CL_BRANCH1 is NOT there"
# fi
# exit

if [[ $BRANCHES == *$BRANCH* ]]; then
    echo "Closing hg $BRANCH, and merging with default"
    if [ "$IOC_OWNER" = "" ]; then
        hg up $BRANCH
        hg ci -m "Merrged/Closed branch $BRANCH" --close-branch
        hg up default
        hg merge $BRANCH
        hg ci -m merge
    else
        sudo -Eu $IOC_OWNER bash -c "hg up $BRANCH"
        sudo -Eu $IOC_OWNER bash -c "hg ci -m \"Merged/Closed branch $BRANCH\" --close-branch"
        sudo -Eu $IOC_OWNER bash -c "hg up default"
        sudo -Eu $IOC_OWNER bash -c "hg merge $BRANCH"
        sudo -Eu $IOC_OWNER bash -c "hg ci -m merge"
    fi
    echo "Merged hg $BRANCH branch, into default"
else
    echo "$BRANCH branch not present, and can not be merged/closed"
fi

if [[ $BRANCHES ==  *$CL_BRANCH* ]]; then
    echo "Closing hg $CL_BRANCH"
    if [ "$IOC_OWNER" = "" ]; then    
        hg up -C $CL_BRANCH
        hg commit --close-branch -m "close branch $CL_BRANCH"
        hg up -C default
    else
        sudo -Eu $IOC_OWNER bash -c "hg up -C $CL_BRANCH"
        sudo -Eu $IOC_OWNER bash -c "hg commit -- close-branch -m \"close branch $CL_BRANCH\""
        sudo -Eu $IOC_OWNER bash -c "hg up -C default"       
    fi
    echo "$CL_BRANCH branch closed"
else
    echo "$CL_BRANCH branch not present, and can not be closed"
fi
