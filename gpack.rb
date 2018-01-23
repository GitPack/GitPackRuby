
puts `which git`

## Check is ruby/git module files are properly loaded
if `which git`.chomp != "/apps/git/current/bin/git"
   puts "ERROR: Git and Ruby modules not properly loaded!"
   puts "\tYour .cshrc should have the following lines for gpack to properly work"
   puts "\t\tsetenv MODULEPATH /common/modulefiles"
   puts "\t\tmodule load apps/git-default"
   puts
   puts "The module command also must be installed. If you are having issues please contact Steve Reilly and Aaron Cook"   
   exit
end


## First get the SSH key to tmp
key_url = 'http://allegrogit.allegro.msad/ast/clio-template/raw/master/GitManager/ssh_key/id_rsa'
key_tempfile = Tempfile.new('gpack_ssh')
`wget -O #{key_tempfile.path} #{key_url} &> /dev/null`
$GIT_SSH_COMMAND="ssh -i #{key_tempfile.path} -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
##


grepos = GitCollection.new()

File.open($gbundle_file, "r") do |f|
   lnumber = 1
   
   unlocked = File.exists?('./.gpackunlock')
   
   f.each_line do |line|      
      if !line.index(/^\s*#.*/) && line.index($identifier)
         clean_line = line.gsub($identifier,"")
         new_repo = eval("GitReference.new #{clean_line}")
         
         if unlocked
            new_repo.readonly = false
         end
         
         grepos.add_ref(new_repo)
      end
      
      lnumber=lnumber+1
   end
end

case ARGV[0]
   when "install"
      grepos.print
      grepos.clone
   when "update"
      grepos.print
      if ARGV[1] == "-f"
         grepos.update(true)
      else
         grepos.update(false)
      end
   when "check"
      grepos.print
      grepos.check
   when "uninstall"
      grepos.print
      if ARGV[1] == "-f"
         grepos.remove(true)
      else
         grepos.remove(false)
      end
      `rm -f .gpackunlock`
   when "archive"
      grepos.print
      grepos.archive
   when "lock"
      `rm -f .gpackunlock`
      grepos.set_writeable(false)
   when "unlock"
      `echo "UNLOCKED" >> .gpackunlock`
      grepos.set_writeable(true)
   when "clean"
      grepos.clean
   else "help"
      puts README
end


key_tempfile.close
