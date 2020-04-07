#!/bin/bash

# Author: K. Gofron
# Date: 2020-2-12
# Source: https://github.com/kgofron/hg2git.git

# EXAMPLE: Convert local hg repository, with autosave for pmac motion controller, 
# with gitlab repo existing (overwrite)
# hg2git.sh -r . -as pAS --force
# hg2git.sh -r . -as pAS -url "https://gitlab.nsls2.bnl.gov/xf/10id/iocs/xf10idd-ioc1/" --force

FST_EXPRT="/tmp/fast-export"  # fast-export clone directory
REPO=""
#PFX="hg2git"
#SFX_STATE="state"
GFI_OPTS=""
C_OPT=""
AS_OPTS=""   # AutoSave options

# More compact directory/folder
DIR_S=$(dirname "$PWD")
REPO_S=$(basename "$PWD")
echo "Current directory and repo=$DIR_S, $REPO_S"
#GIT_URL="https://github.com/kgofron/"
GIT_URL="https://gitlab.nsls2.bnl.gov/xf/10id/iocs/xf10idd-ioc1/"
GIT_REPO="$GIT_URL$REPO_S"
echo "Git repo=$GIT_REPO"

USAGE="[--quiet] [-r <repo>] [--force] [-D <max>] [-A <file>] [-M <name>]"
LONG_USAGE="Import hg repository <repo> up to either tip or <max>
If <repo> is omitted, use last hg repository as obtained from state file,
GIT_DIR/$PFX-$SFX_STATE by default.


Note: The argument order matters.
Options:
	--quiet   Quiet option passed to git push
	-r <repo> Mercurial repository to import (InPlace='.')
	--force   Force push to git repository if it exists.
	-D7       Debian 7 version to import
	-as       Autosave files for pmac, camera, ... (pmac->pAS, camera->cAS)
	-url      URL of the git repo to push to
	-A <file> Read author map from file
	          (Same as in git-svnimport(1) and git-cvsimport(1))
	-M <name> Set the default branch name (defaults to 'master')
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
    -r|--r|--re|--rep|--repo)
      shift
      REPO="$1"
      echo $REPO
      ;;
    --q|--qu|--qui|--quie|--quiet)
      GFI_OPTS="$GFI_OPTS --quiet"
      ;;
    --force)
      # pass --force to git-fast-import and hg-fast-export.py
      GFI_OPTS="$GFI_OPTS --force"
      IGNORECASEWARN="";
      break
      ;;
    -D7|--Deb7|--Debian7)
      # Debian 7 requires v160914, or maybe v180610
    #  shift
#      C_OPTS="-b v160914"
      C_OPTS="-b v180317"
      ;;
    -as|--autoS|--autoSave) # PMAC AutoSave as/req, as/save
      shift
      AS_OPTS="$1"
      echo "Autosave=AS_OPTS"
      ;;
    -url|--URL|--gitURL)
      shift
      GIT_URL="$1"
      echo "Git URL->$GIT_URL" 
      GIT_REPO="$GIT_URL$REPO_S"
      ;;
    -*)
      # pass any other options down to hg2git.py
      break
      ;;
    *)
      break
      ;;
  esac
  shift
done

echo "Preparing environment"
rm /tmp/authors
rm -rf /tmp/fast-export

git clone $C_OPTS https://github.com/frej/fast-export.git $FST_EXPRT
#cd /tmp/fast-export 
#git checkout tags/v160914  # Debian 7
echo "Cloning mercurial repository"
# git checkout tags/v180317 # {Debian7: v160914, support for git >= 2.10}

# cd /tmp/hg-repo # Repo to be converted InPlace

# Authors cleanup might be needed, then hg-fast-export with -A flag
# echo "Getting authors informations"
# hg log | grep user: | sort | uniq | sed 's/user: *//' > /tmp/tmp_authors
# while read -r line 
# do
#     echo "\"$line\"=\"$line\"" >> /tmp/authors
# done < /tmp/tmp_authors

# Test if it is a git directory
if [ -d .git ]; then
    echo ".git repo exists, perform manual migration";
    exit; # exit since it is a git repo.
else
    echo "Not a git repository, preceed with hg->git conversion";
fi

# Test if it is a mercurial repo "hg root"
#hg --cwd the/path/you/want/to/test root

if [ ! -d .hg ]; then
    echo "Not hg repository, no conversion";
    exit;
else # Hg->git migration InPlace (inside hg repository))
    echo "Starting hg-> git mibration, since .hg exists";

    # Create .gitignore file if does not exist
    if [ -f ".gitignore" ]; then
        echo ".gitignore exists"
    else
        cp .hgignore .gitignore
        echo ".hg" >> .gitignore
        # echo "*~" >> .gitignore
        # echo "db/" >> .gitignore
        # echo "dbd/" >> .gitignore
        # echo "O.linux-x86_64/" >> .gitignore
        # echo "O.Common/" >> .gitignore
        # echo "envPaths" >> .gitignore
        # echo "bin/" >> .gitignore
        # echo "records.dbl" >> .gitignore
        # echo "as/" >> .gitignore
        # echo "save_old/" >> .gitignore
        # echo "TMP/" >> .gitignore
        # echo ".git/" >> .gitignore
        # echo ".hg/" >> .gitignore
    fi
    # .gitignore created

    git init
    /tmp/fast-export/hg-fast-export.sh -r . --force
    #/tmp/fast-export/hg-fast-export.sh -r . -A /tmp/authors --force
    # git clean         # did not work 
    # git checkout HEAD # does not work for InPlace conversion
    git reset --hard HEAD   # the files shows as deleted in 'git status'
    git add .gitignore
    case $AS_OPTS in   # autosave
      pAS|pmacAS|pmacAutoSave)          # pmac autosave
        git add -f as/req/info_positions.req as/req/info_settings.req
        git add -f as/save/info_positions.sav as/save/info_settings.sav
        echo "pmac as files"
        ;;
      cAS|cameraAS|cameraAutoSave)
        git add -f autosave/auto_settings.sav
        echo "camera autosave files"
        ;;
    esac
    git commit -m ".gitignore tracked"
#    git remote add origin https://github.com/kgofron/ez4axis1
    git remote add origin $GIT_REPO
    git push -u origin master $GFI_OPTS
fi  # .hg exists, .git does not exist; Conversion hg-> git is automatic
