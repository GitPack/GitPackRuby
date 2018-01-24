README=%{
=====
GitPack
=====

Python based git repository manager. Conceptually simular to a package manager like pip, rubygems, ect. GitPack handles the distrubuting of repositories without being tied to a specific language; although it does use python to execute commands. It specifically is designed to control multiple git repository dependancies on a multiple user project. The default behavior is to clone the repositories in a read-only mode, however this can be configured.

* Clones multiple repositories in parallel.
* Controls read-only permissions on cloned repositories.
* Pulls multiple repositoires in parallel.
* Easy clean of repositories that do not have a clean git status.
* Submodule compatible

Structure
-----
* ./gpack - The main exectuable. GitPack is self updating and downloads the latest ver. of master from this repository.
* ./GpackRepos - The main file that GitPack uses to store information about remote repositories URL, the local desitinations where the repositories should be cloned, and user configuration options like read-only, SSH keys, ect. This file is in YAML format
* ./.gpacklock - Used to store the repository read-only status.

Dependancies
-----
* Tested in Ruby 2.3

Setup
-----
Download the gpack bash script to a local directory and make the file executable:
    
.. code::

    wget https://raw.githubusercontent.com/GitPack/GitPack/master/gpack
    chmod u+x ./gpack

Add repos to GpackRepos file using gpack, an example is shown below:

.. code::

    ./gpack add git@github.com:GitPack/GitPack.git ./GitPack

Basic Usage
-----

Installs all repos in GpackRepos file:

.. code::

    ./gpack install

Update installed repos in GpackRepos file:

.. code::
    
    ./gpack update


GpackRepos
----------

.. code-block:: bash

   test1:
       url: git@github.com:GitPack/TestRepo1.git
       localdir: ./repos/test1
       branch: master
       lock: true

   test2:
       url: git@github.com:GitPack/TestRepo2.git
       localdir: ./repos/test2
       branch: master
       lock: false

   test3:
       url: git@github.com:GitPack/TestRepo3.git
       localdir: ./repos/test3
       branch: master
       lock: false

   test3_hash:
       url: git@github.com:GitPack/TestRepo3.git
       localdir: ./repos/test3_hash
       branch: b41e58af7
       lock: false

   test1_tag:
       url: git@github.com:GitPack/TestRepo1.git
       localdir: ./repos/test1_tag
       branch: v2.0
       lock: false
      
   config:
      parallel: true
      lock: true
      #remote_key: http://allegrogit.allegro.msad/ast/clio-template/raw/master/GitManager/ssh_key/id_rsa



Core Commands
-------------

**add [url] [directory] [branch]**
   Adds a repo to the GpackRepos file given ssh URL and local directory
   relative to current directory
**check**
   Checks if all repos are clean and match GpackRepos
**status**
   Runs through each repo and reports the result of git status
**clean [repo]**
   Force cleans local repo directory with git clean -xdff
**help**
   Displays this message
**install [-nogui]**
   Clones repos in repo directory
   -nogui doesn't open terminals when installing
**uninstall [repo] [-f]**
   Removes all local repositories listed in the Repositories File
   Add -f to force remove all repositories
**reinstall [repo] [-f]**
   The same as running uninstall then reinstall
**list**
   List all repos in GpackRepos file
**lock [repo]**
   Makes repo read-only, removes from .gpacklock file
**unlock [repo]**
   Allows writing to repo, appends to .gpacklock file
**purge**
   Removes all repos and re-clones from remote
**update [repo]**
   Cleans given repo, resetting it to the default

Git Commands
------------

**branch [repo]**
   Checks branch on current repo
**checkout [repo]**
   Prompts user for branch to checkout. If the branch doesn't exist, ask if
   user wants to create a new one
**push [repo]**
   Pushes local repo changes to origin
   Won't push if on master
**pull [repo]**
   Pulls changes to repo
**tag [repo]**
   Asks user which tag to checkout for a repo. If given tag doesn't exists,
   ask for a new tag to create
Details
-----------
* Maintains a clean local repository directory by parsing GpackRepos for user-defined repositores that they wish to clone.
* By default, all cloned repositories have no write access.

Future Improvements
-----
* GitPack is not Git LFS compatible at the moment. Merge requests with this feature would be accepted.
   
Developers
-----
* Andrew Porter https://github.com/AndrewRPorter
* Aaron Cook https://github.com/cookacounty

}
