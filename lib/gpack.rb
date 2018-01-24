
puts "Using Git Executable #{`which git`}"

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

grepos = parse_gpackrepos()


OptionParser.new do |opts|
  opts.on("-nogui") do
    $SETTINGS["gui"]["show"] = false
  end
  opts.on("-f") do
    $SETTINGS["core"]["force"] = true
  end
  opts.on("-persist","-p") do
    $SETTINGS["gui"]["persist"] = true
  end
  opts.on("-s") do |v|
    $SETTINGS["core"]["parallel"] = false
  end
end.parse!

puts $SETTINGS

case ARGV[0]
   when "install"
      grepos.clone
      grepos.print
      grepos.check
   when "update"
      grepos.print
      grepos.update()
   when "check"
      grepos.check
   when "uninstall"
      grepos.remove()
      `rm -f .gpackunlock`
   when "archive"
      grepos.archive
   when "lock"
      `rm -f .gpackunlock`
      grepos.set_writeable(false)
   when "unlock"
      `echo "UNLOCKED" >> .gpackunlock`
      grepos.set_writeable(true)
   when "rinse"
      grepos.rinse
      grepos.check # check should be clean
   when "reinstall"
      grepos.reinstall
   when "status"
      grepos.status
   when "list"
      grepos.print
   else "help"
      puts README
end

# Close the SSH tempfile
if $SETTINGS["ssh"]["key"]
   $SETTINGS["ssh"]["key"].close
end
