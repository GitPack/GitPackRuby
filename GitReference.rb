module HasProperties
   attr_accessor :props
   attr_accessor :require_attrs
   
   def has_properties *args
      @props = args
      instance_eval { attr_reader *args }
      instance_eval { attr_writer *args }
   end
   
   def has_required *args
      @require_attrs = args
   end

   def self.included base
      base.extend self
   end

   def initialize(args)

      # Attributes required when defining a GitReference
      require_attrs = self.class.require_attrs
   
      # Check that all the required
      args.each do |k,v|
         require_attrs = require_attrs - [k]
      end
      
      if require_attrs.any?
         raise "Must include attributes #{require_attrs} in GitReference definition"
      end

      args.each {|k,v|
         instance_variable_set "@#{k}", v if self.class.props.member?(k)
      } if args.is_a? Hash
   end
end


class GitReference 
   include HasProperties

   has_properties :url, :localdir, :branch, :readonly
   has_required   :url, :localdir, :branch
   
   def initialize args
      # Non-Required defaults
      @readonly   = true
   
      super
   end
   def clone(interactive=true)
    
      #Clone the Git Repository
      checks_failed = false
      
      #check if directory already exists
      if local_exists
         puts "Cloning Warning - Directory #{localdir} already exists! Running checks instead"
         checks_failed = self.check()
      else
         syscmd("git clone #{url} #{localdir} --recursive",interactive)
         self.checkout
         if @readonly
            self.set_writeable(false)
         end
      end
      
      return checks_failed
   end
   
   def update(force_clone,interactive=true)
      command_failed = false
      # Returns true if falure
      if local_exists
         checks_failed = self.check(true) # TODO, should this fail if branch is wrong?
         if !checks_failed
            puts "Updating local repository #{@localdir}"
            if @readonly
               self.set_writeable(true)
            end
            self.checkout
            syscmd("cd #{@localdir} && git pull origin #{branch} --recurse-submodules && git submodule update --init --recursive",interactive)
            if @readonly
               self.set_writeable(false)
            end
            command_failed = false
         else
            command_failed = true
         end
      elsif force_clone
         self.clone
         command_failed = false
      else
         command_failed = true
      end
      return command_failed
   end
   
   def checkout()
      if local_branch() != @branch
         syscmd("cd #{@localdir} && git checkout -B #{@branch} origin/#{@branch} && git submodule update --init --recursive")
      end
   end
   
   def set_writeable(tf)
      if tf
         puts "Setting #{@localdir} to writable"
         chmod_cmd = "chmod u+w" 
      else
         puts "Setting #{@localdir} to read only"
         chmod_cmd = "chmod u-w" 
      end
      find_cmd = "find #{@localdir} -type f -o -type d -not -path '*/.git/*' -not -name '.git' -exec #{chmod_cmd} {} \\;"
      syscmd(find_cmd)
   end
   
   def check(skip_branch=false)
      #Check integrety
      #  Check that URL matches
      #  Check that branch matches
      #  Check that there are no local changes "clean" state
      check_git_writable()
      
      puts "\nRunning checks on local repository #{@localdir}"
      checks_failed = false
      if local_exists
         if skip_branch || local_branch() == @branch
            #puts "\tPASS - Check branch matches #{@branch}"
         else
            puts "\tFAIL - Check branch matches #{@branch}"
            checks_failed = true
         end

         if local_url() == @url
            #puts "\tPASS - Check remote url matches #{@url}"
         else
            puts "\tFAIL - Check remote url matches #{@url}"
            checks_failed = true
         end

         if local_clean()
            #puts "\tPASS - Check local repository clean"
         else
            puts "\tFAIL - Check local repository clean"
            checks_failed = true
         end
         
         if !checks_failed
            puts "PASS - All checks on local repository #{@localdir}"
         else
            puts "FAIL - All checks on local repository #{@localdir}. See previous log for info on which check failed"
         end
      else
         puts "\tFAIL - Check local repository exists"
         checks_failed = true
      end
      return checks_failed
   end
   
   def syscmd(cmd,open_xterm=false)
      if open_xterm
         cmd = "xterm -geometry 90x30 -e \"#{cmd} || read -p 'Command Failed, see log above. Press return to close window'\""
      end
      puts ("#{cmd}").color(Colors::YELLOW)
      #Pass env var to Open3
      stdout_str,stderr_str,status = Open3.capture3({"GIT_SSH_COMMAND" => $GIT_SSH_COMMAND},cmd)
      if stdout_str != "" || stderr_str != ""
         puts "="*30+"START"+"="*28+"\n"
         puts stderr_str
         puts stdout_str
         puts "="*30+"END"+"="*30+"\n"
      end
   end
   
   def remove(force)
      command_failed = false
      if force || !self.check
         puts "Removing local repository #{@localdir}"
         if @readonly
            self.set_writeable(true)
         end
         syscmd("rm -rf #{@localdir}")
         command_failed = false
      else
         command_failed = true
      end
      return command_failed
   end
   
   def rinse(force=false)
      if !@readonly && !force
         puts "Error with repository #{@localdir}\n\t Repositories can only be rinsed when in readonly mode"
         command_failed = true
      else
         syscmd("git clean -xdff")
         syscmd("git reset --hard")
         syscmd("git submodule foreach --recursive git clean -xdff")
         syscmd("git submodule foreach --recursive git reset --hard")
         syscmd("git submodule update --init --recursive")
      end
      
      
      return command_failed
   end
   
   def archive()
      #Archive the Git Repository
      
      checks_failed = false
      
      #check if directory already exists
      if !self.check()
         command_failed = true
      else
         git_ref = local_rev
         dirname = @localdir.match( /\/([^\/]*)\s*$/)[1].chomp
         tarname = "#{dirname}_#{git_ref}.tar.gz"
         tarcmd = "tar -zcvf #{tarname} #{@localdir} > /dev/null"
         syscmd(tarcmd)
      end
      
      return command_failed
   end
   
   def check_git_writable()
      # Make sure .git folder is writable
      
      gitdirs = `find #{localdir} -type d -name ".git"`
      gitdirs.each_line do |dir|
         dir.chomp!
         if !File.writable?(dir)
            puts "Warning, .git folder #{dir} was found read-only. Automatically setting it to writable"
            syscmd("chmod ug+w -R #{dir}")
         end
      end
   end
   
   def local_branch()
      bname = `cd #{@localdir} && git rev-parse --abbrev-ref HEAD`.chomp
      return bname
   end
   
   def local_url()
      urlname = `cd #{@localdir} && git config --get remote.origin.url`.chomp
      return urlname
   end
   
   def local_rev()
      revname = `cd #{@localdir} && git rev-parse --short HEAD`.chomp
      return revname
   end
   
   def local_clean()
      clean = `cd #{@localdir} && git status --porcelain`
      return clean == "" # Empty string means it's clean
   end
   
   def local_exists()
      if Dir.exists?(@localdir)
         return true
      else
         return false
      end
   end
   
end
