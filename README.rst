=====
GitPack
=====

Ruby Implementation of git repository manager. Conceptually simular to a package manager like pip, rubygems, ect. GitPack handles the distrubuting of repositories without being tied to a specific language; although it does use python to execute commands. It specifically is designed to control multiple git repository dependancies on a multiple user project. The default behavior is to clone the repositories in a read-only mode, however this can be configured.

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
**help**
   Displays this message
**install**
   Clones repos in repo directory
   -nogui doesn't open terminals when installing
**uninstall [-f]**
   Removes all local repositories listed in the Repositories File
   Add -f to force remove all repositories
**reinstall **
   The same as running uninstall then reinstall
**list**
   List all repos in GpackRepos file
**lock **
   Makes repo read-only, removes from .gpacklock file
**unlock **
   Allows writing to repo, appends to .gpacklock file
**update [-f]**
   Updates the repositories -f will install if not already installed

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
