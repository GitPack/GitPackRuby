README=%{
=====
GitPack v2.0
=====

From https://github.com/GitPack/GitPackRuby

Ruby Implementation of git repository manager. Conceptually simular to a tool like bundle, gradel, ect. GitPack handles the distrubuting of Git repositories without being tied to a specific language; although it does use ruby to execute commands. GitPack specifically is intended to control multiple git repository dependancies on a project where it is required that multiple user's point to the same commit/branch/tag. GitPack simplifies the usage of Git and can be especially beneficial when working with teams where not every user knows how to manage a git repository. GitPack uses a single file "GpackRepos" to specifiy the URL and local destination of repositories that it should manage.

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
   
# Options for Configuration
#   config:
#      lock: true # Option to disable read-only by default
#      remote_key: http://some.valid.url # Use an external ssh key
#      ssh_command: ssh -v # Custom SSH arguments passed to $GIT_SSH_COMMAND



Core Commands
-------------

**gpack cmd [-f] [-nogui] [-persist] [-s]**
   * -f,--force: Force operation
   * -s,--single: Single threaded, useful for debug
   * -n,--nogui: Do not pop up xterm windows
   * -p,--persist: Keep xterm windows open even if command is successful

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
**uninstall**
   Removes all local repositories listed in the Repositories File
   Add -f to force remove all repositories
**reinstall**
   The same as running uninstall then reinstall
**list**
   List all repos in GpackRepos file
**lock**
   Makes repo read-only, removes from .gpacklock file
**unlock**
   Allows writing to repo, appends to .gpacklock file
**update**
   Updates the repositories -f will install if not already installed


Details
-----------
* Maintains a clean local repository directory by parsing GpackRepos for user-defined repositores that they wish to clone.
* By default, all cloned repositories have no write access.

Future Improvements
-----
* GitPack is not Git LFS compatible at the moment. Merge requests with this feature would be accepted.
* Add command is not implemented
* Allow GitPack commands to operate on a per-repository basis
* Lock/Unlock of individual repositores. (Python version has this)
   
Developers
-----
* Andrew Porter https://github.com/AndrewRPorter
* Aaron Cook https://github.com/cookacounty

}
