
def gpack(opts)
puts opts.inspect
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
download_ssh_key()
set_ssh_cmd()

OptionParser.new do |opts|
  opts.on("-n","--nogui") do
    $SETTINGS["gui"]["show"] = false
  end
  opts.on("-f","--force") do
    $SETTINGS["core"]["force"] = true
  end
  opts.on("-p","--persist") do
    $SETTINGS["gui"]["persist"] = true
  end
  opts.on("-i") do
    $SETTINGS["core"]["install"] = true
  end
  opts.on("-s","--single") do
    $SETTINGS["core"]["parallel"] = false
  end
end.parse!

case opts[0]
   when "install"
      grepos.clone
   when "update"
      grepos.update
   when "check"
      grepos.check
   when "uninstall"
      grepos.remove
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
      grepos.remove
      grepos.clone
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

end
