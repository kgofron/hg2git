# hg2git

Author: Kazimierz Gofron  
Created: February 12, 2020  
Last Updated: April 2, 2020   
Copyright (c): 2020 Brookhaven National Laboratory  

### InPlace migration of mercurial EPICS ioc repository to git

Release version of this converter of EPICS iocs to git are available on github. Please report any problems of feature requests on the issues page of the https://github.com/kgofron/hg2git.

This mercurial to git converter was tested only for inPlace (within hg repo) conversion of EPICS iocs, and supports following options.
* -r . {local inPlace hg repository to be migrated into git/gitlab}
* -D7  {Debian 7 repository; no option when using Debian 10}
* -as pAS {turboPmac ioc autosave files from as/req and as/save}
* -as cAS {areaDetector iocs autosave files}
* -u <owner> {convert repo owned by another user: softioc}
* -url https://github.com/kgofron/mc3 {git destination repository}
* --force {force option for pushing to the destination git repository}

* Debian 7 turboPmac ioc conversion example with autosave files
```
kgofron@xf10idd-ioc1:/epics/iocs/mc3$ hg2git.sh -r . -D7 -as pAS -url https://github.com/kgofron/ --force`
```
* Debian 10 turboPmac ioc conversion example without autosave files
```
kaz@debian10:~/ioc1/mc3$ hg2git.sh -r . -url https://github.com/kgofron/  --force
```

### Structure same as hg
* gitlab.nsls2.bnl.gov/xf/10id/iocs/xf10idd-ioc1
  * mc1
  * mc2
  * cam-onAis
  
### Installation

**Note - The hg2git has only been tested on Debian 7 and Debian 10**

Clone this repository to a convinient location, and add that location to PATH
```
cd ~/src
git clone https://github.com/kgofron/hg2git
export PATH=$PATH:~/src/hg2git
```

From within the hg repository issue the hg2git command followed by options
The local name of the repository folder and github/gitlab must be same. The github/gitlab repository on the server must be created prior to conversion, or push will not work. The --force option overwrites the git repository on the gitlab/github server.
```
$ hg2git.sh -r . -D7 -as pAS -url https://github.com/kgofron/ --force`
```
This hg2git converter installs the fast-export converter in the /tmp/ directory on linux system.

### Some Known Issues
* The current version was tested for pmac motor iocs autosave (-as pAS)
* Conversion of areaDetector iocs autosave is under development (-as aAS)
* Other types of iocs autosave might be added in the future, per request.
