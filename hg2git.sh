#!/bin/bash

# Author: K. Gofron
# Date: 2020-2-12
# Source: https://github.com/kgofron/hg2git.git

# EXAMPLE: Convert local hg repository, with autosave for pmac motion controller, 
# with gitlab repo existing (overwrite)
# hg2git.sh -r . -as pAS --force
# hg2git.sh -r . -as pAS -url "https://gitlab.nsls2.bnl.gov/xf/10id/iocs/xf10idd-ioc1/" --force
# hg2git.sh -r . -D7 -as pAS -u softioc -url https://github.com/kgofron/ --force
# hg2git/hg2git.sh -r . -D7 -as cAS -u softioc -url https://gitlab.nsls2.bnl.gov/xf/10id/iocs/xf10idd-ioc1/  --force
# hg2git/hg2git.sh -r . -b -D7 -as cAS -u softioc -url https://gitlab.nsls2.bnl.gov/xf/10id/iocs/xf10idd-ioc1/  --force

FST_EXPRT="/tmp/fast-export"  # fast-export clone directory
REPO=""   # Repository name
#PFX="hg2git"
#SFX_STATE="state"
GFI_OPTS=""   # Git flags such as --force, ...
C_OPT=""      # fast-export release, Deb7 requires v160914, but v180317 works as well.
AS_OPTS=""    # AutoSave options
B_OPTS="--all"     # Branch push options {active| --all}

# Get directory/folder
DIR_S=$(dirname "$PWD")
REPO_S=$(basename "$PWD")
BRANCH=$(hg branch)
echo "Current directory and repo=$DIR_S, $REPO_S"
#GIT_URL="https://github.com/kgofron/"
GIT_URL="https://gitlab.nsls2.bnl.gov/xf/10id/iocs/xf10idd-ioc1/"
GIT_REPO="$GIT_URL$REPO_S.git"
echo "Git repo defaults to=$GIT_REPO"
echo "Hg repo branch=$BRANCH"

USAGE="[--quiet] [-r <repo>] [-b <branch>] [--force] [-D7] [-as <pAS>] [-u <user>] [-A <file>] [-M <name>]"
LONG_USAGE="Import hg repository <repo> up to either tip or <max>
If <repo> is omitted, use last hg repository as obtained from state file,
GIT_DIR/$PFX-$SFX_STATE by default.

Note: The argument order matters.
Options:
	--quiet     Quiet option passed to git push 
	-r <repo>   Mercurial repository to import (InPlace='.')
  -b          Push only active branch
	--force     Force push to git repository if it exists.
	-D7         Debian 7 version to import
	-as <AS>    Autosave files for pmac, camera, ... (pmac->pAS, camera->cAS)
	-u <user>   IOC Owner account (e.g. softioc)
	-url <url>  URL of the git repo to push to
	-A <file>   Read author map from file
	            (Same as in git-svnimport(1) and git-cvsimport(1))
	-M <name>   Set the default branch name (defaults to 'master')
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
      echo "Repository=$REPO"
      ;;
    -b|--branch)   # a=activeBranch, all=allBranches
      B_OPTS="$BRANCH"
      echo "Only push active $BRANCH branch"
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
#      C_OPTS="-b v160914"
      C_OPTS="-b v180317"
#      C_OPTS="-b v200213"
      ;;
    -u|--usr|--user)
      # Owner of the ioc directory
      shift
      IOC_OWNER="$1"
      ;;
    -as|--autoS|--autoSave) # PMAC AutoSave as/req, as/save
      shift
      AS_OPTS="$1"
      echo "Autosave=$AS_OPTS"
      ;;
    -url|--URL|--gitURL)
      shift
      GIT_URL="$1"
      GIT_REPO="$GIT_URL$REPO_S.git"
      echo "Git repo->$GIT_REPO"
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
      if [ "$IOC_OWNER" = "" ]
      then
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
      else
        sudo -Eu $IOC_OWNER bash -c "cp .hgignore .gitignore"
        sudo -Eu $IOC_OWNER bash -c "echo ".hg" >> .gitignore"
      fi	
    fi    # .gitignore created

    if [ "$IOC_OWNER" = "" ]
    then
      git init
	    /tmp/fast-export/hg-fast-export.sh -r . --force
      if [ ! "$BRANCH" = "default" ]; then  # not on the default branch
        git checkout --force $BRANCH
      fi
	    git reset --hard HEAD   # the files shows as deleted in 'git status'
	    git add .gitignore	
    else
	    sudo -Eu $IOC_OWNER bash -c "git init"
	    sudo -Eu $IOC_OWNER bash -c "/tmp/fast-export/hg-fast-export.sh -r . --force"
      if [ ! "$BRANCH" = "default" ]; then  # not on the default branch
        sudo -Eu $IOC_OWNER bash -c "git checkout --force $BRANCH"
      fi      
	    sudo -Eu $IOC_OWNER bash -c "git reset --hard HEAD"   # the files shows as deleted in 'git status'
	    sudo -Eu $IOC_OWNER bash -c "git add .gitignore"	
    fi
    
    case $AS_OPTS in   # autosave
	  pAS|pmacAS|pmacAutoSave)          # pmac as/req, as/save
	    if [ "$IOC_OWNER" = "" ]
	    then	    
        git add -f as/req/info_positions.req as/req/info_settings.req
        git add -f as/save/info_positions.sav as/save/info_settings.sav
	    else
        sudo -Eu $IOC_OWNER bash -c "git add -f as/req/info_positions.req as/req/info_settings.req"
        sudo -Eu $IOC_OWNER bash -c "git add -f as/save/info_positions.sav as/save/info_settings.sav"
	    fi		    
	    echo "pmac as files"
        ;;
	  cAS|cameraAS|cameraAutoSave)  # areaDetector autosave
      if [ "$IOC_OWNER" = "" ]
	    then 
        git add -f autosave/auto_settings.sav
      else
        sudo -Eu $IOC_OWNER bash -c "git add -f autosave/auto_settings.sav"	       
      fi	   
        echo "camera autosave files"
      ;;
    esac

    if [ "$IOC_OWNER" = "" ]
    then
        git commit -m ".gitignore tracked"
        git remote add origin $GIT_REPO
        # git push -u origin master $GFI_OPTS # push only master branch
        # git push --set-upstream origin $BRANCH $GFI_OPTS # push feature branch
        # git push -u origin --all $GFI_OPTS  # push all branches
        # git push -u origin --tags $GFI_OPTS
        git push -u origin $B_OPTS $GFI_OPTS  # push all branches
        git push -u origin --tags $GFI_OPTS
    else
        sudo -Eu $IOC_OWNER bash -c "git commit -m '.gitignore tracked'"
        sudo -Eu $IOC_OWNER bash -c "git remote add origin $GIT_REPO"
#        sudo -Eu $IOC_OWNER bash -c "git push -u origin master $GFI_OPTS"  # push only master branch
#        sudo -Eu $IOC_OWNER bash -c "git push --set-upstream origin $BRANCH $GFI_OPTS"  # push feature branch
        # sudo -Eu $IOC_OWNER bash -c "git push -u origin --all $GFI_OPTS"  # all branches
        # sudo -Eu $IOC_OWNER bash -c "git push -u origin --tags $GFI_OPTS"  # all branches
        sudo -Eu $IOC_OWNER bash -c "git push -u origin $B_OPTS $GFI_OPTS"  # all branches
        sudo -Eu $IOC_OWNER bash -c "git push -u origin --tags $GFI_OPTS"  # all branches
   fi
    
fi  # .hg exists, .git does not exist; Conversion hg-> git is automatic
