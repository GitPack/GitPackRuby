
puts `which git`

## TODO - Check propery ruby and git versions
## Check is ruby/git module files are properly loaded
#if `which git`.chomp != "/apps/git/current/bin/git"
#   puts "ERROR: Git and Ruby modules not properly loaded!"
#   puts "\tYour .cshrc should have the following lines for gpack to properly work"
#   puts "\t\tsetenv MODULEPATH /common/modulefiles"
#   puts "\t\tmodule load apps/git-default"
#   puts
#   exit
#end


## TODO implement SSH key option
custom_ssh_key = false
if custom_ssh_key
   key_url = custom_ssh_url
   key_tempfile = Tempfile.new('gpack_ssh')
   `wget -O #{key_tempfile.path} #{key_url} &> /dev/null`
   $GIT_SSH_COMMAND="ssh -i #{key_tempfile.path} -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
   ##
end

grepos = parse_gpackrepos($gbundle_file)

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
   when "rinse"
      grepos.rinse
   when "reinstall"
      grepos.reinstall
   else "help"
      puts README
end

if custom_ssh_key
   key_tempfile.close
end
