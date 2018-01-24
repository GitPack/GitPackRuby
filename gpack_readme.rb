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
* Tested in Python 3.4.5

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

    config:
        remote_key: http://nhlinear.eng.allegro.msad/ast/clio-template/raw/master/GitManager/ssh_key/id_rsa
        lock: true

    test1:
        url: git@allegrogit.allegro.msad:aporter/test1.git
        local_dir: ./repos/test1
        branch: master

    test2:
        url: git@allegrogit.allegro.msad:aporter/test2.git
        local_dir: ./repos/test2
        branch: master

    test3:
        url: git@allegrogit.allegro.msad:aporter/test3.git
        local_dir: ./repos/test3
        branch: master

    name:
        branch: feat/gui
        local_dir: ./repos/iogen
        url: git@allegrogit.allegro.msad:AST-digital/iogen.git


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
