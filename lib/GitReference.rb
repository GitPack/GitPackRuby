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
   def clone()
    
      #Clone the Git Repository
      checks_failed = false
      
      #check if directory already exists
      if local_exists
         puts "Cloning Warning - Directory #{localdir} already exists! Running checks instead"
         checks_failed = self.check()
      else
         status = syscmd("git clone #{url} #{localdir} --recursive",true,false)
         self.checkout
         if @readonly
            self.set_writeable(false)
         end
         if status != 0
            checks_failed = true
         end
         
      end
      
      return checks_failed
   end
   
   def update()
      force_clone = $SETTINGS["core"]["force"]
      command_failed = false
      # Returns true if falure
      if local_exists
         checks_failed = self.check(true) # TODO, should this fail if branch is wrong?
         if !checks_failed
            puts "Updating local repository #{@localdir}"
            if @readonly
               self.set_writeable(true)
            end
            syscmd("git fetch origin",true)
            self.checkout
            syscmd("git submodule update --init --recursive")
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
      if is_branch()
         checkout_cmd = "checkout -B #{@branch} origin/#{@branch}" # Create a local branch
      else
         checkout_cmd = "checkout #{@branch}" # Direct checkout the tag/comit
      end
      syscmd("git #{checkout_cmd} && git submodule update --init --recursive")  
   end
   
   def set_writeable(tf)

      if tf
         puts "Setting #{@localdir} to writable"
         perms = "u+w" 
      else
         puts "Setting #{@localdir} to read only"
         perms = "a-w" 
      end
      
      file_paths = []
      ignore_paths = []
      if local_exists()
         Find.find(@localdir) do |path|
            # Ignore .git folder
            if path.match(/.*\/.git$/) || path.match(/.*\/.git\/.*/)
               ignore_paths << path
            else
               file_paths << path
               #FileUtils.chmod 'a-w', path
               FileUtils.chmod(perms,path) if File.exist?(path)
            end
         end
      end
      
      # Useful for debug
      #puts "IGNORED PATHS\n"+ignore_paths.to_s
      #puts "FOUND_PATHS\n"+file_paths.to_s
      
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
         if !skip_branch
            if is_branch()
               bname = @branch
            else
               bname = rev_parse(@branch)
            end
            puts bname
            branch_valid = local_branch() == bname
            if !branch_valid
               puts "\tFAIL - Check branch matches #{@branch} rev #{bname}"
               puts "\t\tLocal  Branch abbrev    : '#{rev_parse("HEAD",true)}'"
               puts "\t\tLocal  Branch SHA       : '#{rev_parse("HEAD")}'"
               puts "\t\tSpecified Branch        :    '#{@branch}'"
               puts "\t\tSpecified Branch abbrev : '#{rev_parse(@branch)}'"
               puts "\t\tSpecified Branch SHA    : '#{rev_parse(@branch,true)}'"
               checks_failed = true
            end
         end

         if local_url() == @url
            #puts "\tPASS - Check remote url matches #{@url}"
         else
            puts "\tFAIL - Check remote url matches #{@url}"
            puts "\t\tLocal URL #{local_url()}'"
            puts "\t\tRemote URL #{@url}'"
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
   
   def syscmd(cmd,open_xterm=false,cd_first=true)
      if cd_first
         cmd = "cd #{@localdir} && #{cmd}"
      end
      if open_xterm && $SETTINGS["gui"]["show"]
         if $SETTINGS["gui"]["persist"]
            hold_opt = "-hold"
         end
         cmd = "xterm #{hold_opt} -geometry 90x30 -e \"#{cmd} || echo 'Command Failed, see log above. Press CTRL+C to close window' && sleep infinity\""
      end
      cmd_id = Digest::SHA1.hexdigest(cmd).to_s[0..4]
      #Pass env var to Open3
      ssh_cmd = $SETTINGS["ssh"]["cmd"]
      if ssh_cmd
         args = {"GIT_SSH_COMMAND" => ssh_cmd}
      else
         args = {}
      end
      stdout_str,stderr_str,status = Open3.capture3(args,cmd)
      
      puts "="*30+"COMMAND ID #{cmd_id}"+"="*28+"\n"
      puts ("#{cmd}").color(Colors::YELLOW)
      if stdout_str != "" || stderr_str != ""
         puts "="*30+"COMMAND #{cmd_id} LOG START"+"="*28+"\n"
         puts stderr_str
         puts stdout_str
         puts "="*30+"COMMAND #{cmd_id} LOG END"+"="*30+"\n"
      end
      status
   end
   
   def localcmd(cmd_str)
      return `cd #{@localdir} && #{cmd_str}`.chomp
   end
   
   def remove()
      force = $SETTINGS["core"]["force"]
      command_failed = false
      if force || !self.check
         puts "Removing local repository #{@localdir}"
         if @readonly
            self.set_writeable(true)
         end
         syscmd("rm -rf #{@localdir}",false,false)
         command_failed = false
      else
         command_failed = true
      end
      return command_failed
   end
   
   def rinse()
      force = $SETTINGS["core"]["force"]
      if !@readonly && !force
         puts "Error with repository #{@localdir}\n\t Repositories can only be rinsed when in readonly mode"
         command_failed = true
      else
         self.set_writeable(true)
         status = syscmd( \
         "git fetch origin && " \
         "git clean -xdff && "  \
         "git reset --hard && " \
         "git submodule foreach --recursive git clean -xdff && " \
         "git submodule foreach --recursive git reset --hard && " \
         "git submodule update --init --recursive")
         self.checkout
         self.set_writeable(false)
         if !status
            command_failed = true
            puts "Rinse command failed for repo #{@localdir}, check log"
         end
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
   def status
      self.print()
      syscmd("git status && echo 'Git Branch' && git branch && echo 'Git SHA' && git rev-parse HEAD")
      return false
   end

   def is_branch()
      #check if branch ID is a branch or a tag/commit
      return system("cd #{localdir} && git show-ref -q --verify refs/remotes/origin/#{@branch}")
   end
   
   def local_branch()
      if is_branch()
         bname = rev_parse("HEAD",true)
      else
         bname = rev_parse("HEAD")
      end
      return bname
   end
   
   def rev_parse(rev,abbrev=false)
      if abbrev
         rp = localcmd("git rev-parse --abbrev-ref #{rev}")
      else
         rp = localcmd("git rev-parse #{rev}")
      end
      return rp
   end
   
   def local_url()
      urlname = localcmd("git config --get remote.origin.url")
      return urlname
   end
   
   def local_rev()
      revname = localcmd("git rev-parse --short HEAD")
      return revname
   end
   
   def local_clean()
      clean = localcmd("git status --porcelain")
      return clean == "" # Empty string means it's clean
   end
   
   def local_exists()
      if Dir.exists?(@localdir)
         return true
      else
         return false
      end
   end
   
   def print()
      puts "Reference #{@url}\n\tlocaldir-#{@localdir}\n\tbranch-#{@branch}\n\treadonly-#{@readonly}"
   end
   
end
