README=%{
Git Package Manager
   Uses a single file to describe a list of repositories that should be populated in a local area.
   These repositories are automatically cloned into a specified local folder.
   Also allows these local repositories to be updated as a group and checked for consistancy.
   The concept for Git Package Manager was based on Ruby Gemfiles

Usage
   #{$identifier} [OPTION]
   
Primary Options

   help
      Display this message
      
   install
      Clone the repositories listed in the Repositories File into the local area
      Will return a warning if these repositories exist and fail consistancy checks
      Install assumes you can clone automatically from a given URL. 
         If your SSH key is not setup on the remote, this command will fail!
         
   update
      Pulls the repositories listed in the Repositories File.
      If a repository fails the consitancy check run before the update, it will not be updated and a warning is given.
      Adding a "-f" to this option will cause the update to 
         clone the repository if it does not already exist "#{$identifier} update -f"
         
   uninstall
      Removes the local repositories listed in the Repositories File.
      The repositories are only removed if they pass the consistancy check before the remove
      Add "-f" to force uninstall without consistancy checks 
         "#{$identifier} uninstall -f" (Doing so may lose local data)
         
   archive
      Create a tar.gz of the local repositories listed in the Repositories File. 
      Name of the repo will be called
         \#{localdir}_\#{git_rev}.tar.gz
            localdir is the local directory
            git_rev is the short name for the current git revision (git rev-parse --short HEAD)
            
   clean
      Force cleaning of the repositories. Local data will be removed and repopulated.
      Equivalent to running
         uninstall -f
         install
            
Advanced Options

   lock
      Make the repository read only (default).
      
   unlock
      Make the repositories editable. A file called .gpacklock is created by this command
      and a chmod is run
      
Package Manger Repositories File "#{$gbundle_file}"

   This file describes the information for each repository that should be cloned and updated locally.
   Each line is a seperate local repository and can have several 
      fields that must be specified along with some optional fields
   
   Required Specifiers
      :url
         The URL from which to clone from and pull. This will be set to "origin" automatically by git
      :localdir
         The local directory to clone the repository into
      :branch
         The branch to checkout. This can also be a tag or commit (anything that is recognized by git checkout)
   
   Optional Specifiers
      :readonly
         Repository will be made readonly. There is a slight performance impact since the directory
            file permissions are changed each time update is called.
      
}
