
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
   when "status"
      grepos.status
   else "help"
      puts README
end

# Close the SSH tempfile
if $remote_key
   $remote_key.close
end
