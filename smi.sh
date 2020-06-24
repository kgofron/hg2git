#!/bin/bash

# smi.sh
# Author: K. Gofron <kgofron@bnl.gov>
# Date: 2020-6-24
#
# SMI (12ID) beamline has existing local gitlab repository named 'origin'=http://xf12id-ws3/smi/
# The NSLS2 gitlab repo expacts default of 'origin'=https://gitlab.nsls2.bnl.gov/xf/12id1/iocs/xf12ida-ioc1/
# This repo name conflict is resolved by renaming local repo as 'smi', and NSLS2 repo as 'origin'
#
# kgofron@xf12ida-ioc1:/epics/iocs/a1mc1$ git remote rename origin smi
# kgofron@xf12ida-ioc1:/epics/iocs/a1mc1$ git remote add origin https://gitlab.nsls2.bnl.gov/xf/12id1/iocs/xf12ida-ioc1/a1mc1.git
#
# kgofron@xf12ida-ioc1:/epics/iocs/a1mc1$ git remote -v
# origin	https://gitlab.nsls2.bnl.gov/xf/12id1/iocs/xf12ida-ioc1/a1mc1.git (fetch)
# smi	http://xf12id-ws3/smi/a1mc1.git (fetch)


# Get directory/folder
DIR_S=$(dirname "$PWD")
REPO_S=$(basename "$PWD")
REPO_NAME=$(git remote)
REPO_LOCAL="smi"
REPO_NSLS2="origin"
REPO_RENAMED=""

echo "Git dir=$DIR_S"
echo "Git repo=$REPO_S"
echo "Git repo Name=$REPO_NAME"

GIT_URL="https://gitlab.nsls2.bnl.gov/xf/12id1/iocs/xf12ida-ioc1/"
GIT_REPO="$GIT_URL$REPO_S.git"
echo "Git repo defaults to=$GIT_REPO"

if [[ $REPO_NAME = $REPO_NSLS2 ]]; then  # SMI local repo name is origin
    git remote rename origin $REPO_LOCAL  # local repo renamed to smi
    echo "Renaming local repo from orign to=$REPO_LOCAL"
else
    echo "git local repo named origin does not exist"
fi

REPO_RENAMED=$(git remote)
echo "Repo renamed=$REPO_RENAMED"
if [[ $REPO_RENAMED = $REPO_LOCAL ]]; then  # local repo named smi
    echo "Git repo name is smi=$REPO_RENAMED"
    git remote add origin $GIT_REPO   # add remote repo  NSLS2 origin
else
    echo "git repo smi does not exist, or multiple repos"
fi

