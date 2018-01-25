#!/bin/env ruby
$VERBOSE=nil

require 'tempfile'
require 'open3'
require 'yaml'
require 'open-uri'
require 'digest/sha1'
require 'rdoc'
require 'find'
require 'fileutils'
require 'optparse'

$SETTINGS = { \
   "core" => {"repofile" => "GpackRepos", "force" => false, "parallel" => true},
   "gui" => {"persist" => false, "show" => true},
   "ssh" => {"key_url" => false, "key" => false, "command" => false}
}

class Colors
   COLOR1 = "\e[1;36;40m"
   COLOR2 = "\e[1;35;40m"
   NOCOLOR = "\e[0m"
   RED = "\e[1;31;40m"
   GREEN = "\e[1;32;40m"
   DARKGREEN = "\e[0;32;40m"
   YELLOW = "\e[1;33;40m"
   DARKCYAN = "\e[0;36;40m"
end

class String
   def color(color)
      return color + self + Colors::NOCOLOR
   end
end
README=%{
=====
GitPack
=====

From https://github.com/GitPack/GitPackRuby

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
      lock: true
      remote_key: http://some.valid.url



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
   
Developers
-----
* Andrew Porter https://github.com/AndrewRPorter
* Aaron Cook https://github.com/cookacounty

}
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
         self.set_writeable(false) if @readonly
         
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
            self.set_writeable(true) if @readonly
            syscmd("git fetch origin",true)
            self.checkout
            syscmd("git submodule update --init --recursive")
            self.set_writeable(false) if @readonly
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
            branch_valid = local_branch() == bname
            if !branch_valid
               puts "\tFAIL - Check branch matches #{@branch} rev #{bname}".color(Colors::RED)
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
            puts "\tFAIL - Check remote url matches #{@url}".color(Colors::RED)
            puts "\t\tLocal URL #{local_url()}'"
            puts "\t\tRemote URL #{@url}'"
            checks_failed = true
         end

         if local_clean()
            #puts "\tPASS - Check local repository clean"
         else
            puts "\tFAIL - Check local repository clean".color(Colors::RED)
            checks_failed = true
         end
         
         if !checks_failed
            puts "PASS - All checks on local repository #{@localdir}"
         else
            puts "FAIL - All checks on local repository #{@localdir}. See previous log for info on which check failed".color(Colors::RED)
         end
      else
         puts "\tFAIL - Check local repository exists".color(Colors::RED)
         checks_failed = true
      end
      return checks_failed
   end
   
   def syscmd(cmd,open_xterm=false,cd_first=true)
      if cd_first
         cmd = "cd #{@localdir} && #{cmd}"
      end
      
      #Pass env var to Open3
      ssh_cmd = $SETTINGS["ssh"]["cmd"]
      if ssh_cmd
         args = {"GIT_SSH_COMMAND" => ssh_cmd}
         puts "custom ssh"
      else
         args = {}
      end
      
      if open_xterm && $SETTINGS["gui"]["show"]
         if $SETTINGS["gui"]["persist"]
            hold_opt = "-hold"
         end
         if ssh_cmd
            cmd = "echo 'GIT_SSH_COMMAND $GIT_SSH_COMMAND' ; #{cmd}"
         end
         cmd = "xterm #{hold_opt} -geometry 90x30 -e \"#{cmd} || echo 'Command Failed, see log above. Press CTRL+C to close window' && sleep infinity\""
      end
      cmd_id = Digest::SHA1.hexdigest(cmd).to_s[0..4]
      
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
         self.set_writeable(true) if @readonly || force
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
         self.set_writeable(true) if @readonly
         status = syscmd( \
         "git fetch origin && " \
         "git clean -xdff && "  \
         "git reset --hard && " \
         "git submodule foreach --recursive git clean -xdff && " \
         "git submodule foreach --recursive git reset --hard && " \
         "git submodule update --init --recursive")
         self.checkout
         self.set_writeable(false) if @readonly
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

$RAISE_WARNING = false

class GitCollection
   attr_accessor :refs

   def initialize
      @refs = []
   end
   def add_ref(ref)
      @refs << ref
   end
   def print()
      puts "="*40+"\n\tGit Reference Summary\n"+"="*40
      @refs.each do |ref|
         ref.print()
      end
   end
   def archive()
      puts "\nCreating archives of local Repositories....."
      raise_warning = ref_loop(refs) { |ref|
         ref.archive
      }
      if raise_warning
         puts "\n"+("="*60+"\nWARNING DURING CLONING!\n\tSome repositories already existed and failed checks.\n\tReview this log or run 'gpack check' to see detailed information\n"+"="*60).color(Colors::RED)
      end
   end   
   def clone()
      puts "\nCloning Repositories....."
      raise_warning = ref_loop(refs) { |ref|
         ref.clone
      }
      if raise_warning
         puts "\n"+("="*60+"\nWARNING DURING CLONING!\n\tSome repositories already existed and failed checks.\n\tReview this log or run 'gpack check' to see detailed information\n"+"="*60).color(Colors::RED)
      end
      print()
      check()
   end
   def rinse()
      puts "\nRinsing Repositories....."
      raise_warning = ref_loop(refs) { |ref|
         ref.rinse
      }
      if raise_warning
         puts ("\n"+"="*60+"\nWARNING DURING Rinse!\n"+"="*60).color(Colors::RED)
      end
   end
   def check()
      puts "\nChecking Local Repositories....."
      raise_warning = ref_loop(refs,true) { |ref|
         ref.check
      }
      if raise_warning
         puts "\n"+("="*60+"\nWARNINGS FOUND DURING CHECK!\n\tReview this log to see detailed information\n" \
            "\tThe following commands can be run to help debug:\n" \
            "\t\tgpack status #Shows the current git status\n" \
            "\t\tgpack rinse #Removes all local changes and untracked files,use with caution\n" \
            +"="*60).color(Colors::RED)
      end
   end
   def status()
      puts "\nStatus of Local Repositories....."
      raise_warning = ref_loop(refs,true) { |ref|
         ref.status
      }
      if raise_warning
         puts "\n"+("="*60+"\nWARNINGS FOUND DURING CHECK!\n\tReview this log to see detailed information\n"+"="*60).color(Colors::RED)
      end
   end
   def update()
      print()
      puts "\nUpdating Repositories.....\n\n"
      puts "Please be patient, this can take some time if pulling large commits.....".color(Colors::GREEN)
      raise_warning = ref_loop(refs) { |ref|
         ref.update()
      }
      if raise_warning
         puts "\n"+("="*60+"\nWARNING DURING UPDATE!\n\tSome repositories failed checks and were not updated.\n\tReview this log or run 'gpack check' to see detailed information\n"+"="*60).color(Colors::RED)
      end
   end
   def remove()
      puts "This will force remove repositories and repopulate. Any local data will be lost!!!\nContinue (y/n)"
      if $SETTINGS["core"]["force"] == true
         do_remove = true
      else
         cont = $stdin.gets.chomp
         do_remove = cont == "y"
      end
      
      if do_remove
         puts "\nRemoving Local Repositories....."

         raise_warning = ref_loop(refs) { |ref|
            ref.remove()
         }
         `rm -f .gpackunlock`
      else
         puts "Abort Uninstall"
      end
      
      if raise_warning
         puts "\n"+("="*60+"\nWARNINGS FOUND DURING REMOVAL!\n\tReview this log to see detailed information\n"+"="*60).color(Colors::RED)
      end
   end
   def set_writeable(tf)
      ref_loop(refs) { |ref|
         ref.set_writeable(tf)
      }
   end
   
   
   def ref_loop(refs, parallel_override=false)
      if $SETTINGS["core"]["parallel"] && !parallel_override
         read, write = IO.pipe
         Parallel.map(@refs) do |ref|

            # Set up standard output as a StringIO object.
            old_stdout = $stdout
            foo = StringIO.new
            $stdout = foo
            
            raise_warning = yield(ref)
            write.puts raise_warning
            
            $stdout = old_stdout
            puts foo.string
            
         end
         write.close
         read_data =  read.read
         #puts read_data
         if read_data.index("true")
            raise_warning = true
         end
      else
         raise_warning = false
         @refs.each do |ref|
            
            ret_warning = yield(ref)
            if ret_warning
               raise_warning = true
            end
         end

      end

      return raise_warning
   end
   
   
end


require 'rbconfig'
#require 'parallel/version'
#require 'parallel/processor_count'


module Parallel
  module ProcessorCount
    # Number of processors seen by the OS and used for process scheduling.
    #
    # * AIX: /usr/sbin/pmcycles (AIX 5+), /usr/sbin/lsdev
    # * BSD: /sbin/sysctl
    # * Cygwin: /proc/cpuinfo
    # * Darwin: /usr/bin/hwprefs, /usr/sbin/sysctl
    # * HP-UX: /usr/sbin/ioscan
    # * IRIX: /usr/sbin/sysconf
    # * Linux: /proc/cpuinfo
    # * Minix 3+: /proc/cpuinfo
    # * Solaris: /usr/sbin/psrinfo
    # * Tru64 UNIX: /usr/sbin/psrinfo
    # * UnixWare: /usr/sbin/psrinfo
    #
    def processor_count
      @processor_count ||= begin
        os_name = RbConfig::CONFIG["target_os"]
        if os_name =~ /mingw|mswin/
          require 'win32ole'
          result = WIN32OLE.connect("winmgmts://").ExecQuery(
            "select NumberOfLogicalProcessors from Win32_Processor")
          result.to_enum.collect(&:NumberOfLogicalProcessors).reduce(:+)
        elsif File.readable?("/proc/cpuinfo")
          IO.read("/proc/cpuinfo").scan(/^processor/).size
        elsif File.executable?("/usr/bin/hwprefs")
          IO.popen("/usr/bin/hwprefs thread_count").read.to_i
        elsif File.executable?("/usr/sbin/psrinfo")
          IO.popen("/usr/sbin/psrinfo").read.scan(/^.*on-*line/).size
        elsif File.executable?("/usr/sbin/ioscan")
          IO.popen("/usr/sbin/ioscan -kC processor") do |out|
            out.read.scan(/^.*processor/).size
          end
        elsif File.executable?("/usr/sbin/pmcycles")
          IO.popen("/usr/sbin/pmcycles -m").read.count("\n")
        elsif File.executable?("/usr/sbin/lsdev")
          IO.popen("/usr/sbin/lsdev -Cc processor -S 1").read.count("\n")
        elsif File.executable?("/usr/sbin/sysconf") and os_name =~ /irix/i
          IO.popen("/usr/sbin/sysconf NPROC_ONLN").read.to_i
        elsif File.executable?("/usr/sbin/sysctl")
          IO.popen("/usr/sbin/sysctl -n hw.ncpu").read.to_i
        elsif File.executable?("/sbin/sysctl")
          IO.popen("/sbin/sysctl -n hw.ncpu").read.to_i
        else
          $stderr.puts "Unknown platform: " + RbConfig::CONFIG["target_os"]
          $stderr.puts "Assuming 1 processor."
          1
        end
      end
    end

    # Number of physical processor cores on the current system.
    #
    def physical_processor_count
      @physical_processor_count ||= begin
        ppc = case RbConfig::CONFIG["target_os"]
        when /darwin1/
          IO.popen("/usr/sbin/sysctl -n hw.physicalcpu").read.to_i
        when /linux/
          cores = {}  # unique physical ID / core ID combinations
          phy = 0
          IO.read("/proc/cpuinfo").scan(/^physical id.*|^core id.*/) do |ln|
            if ln.start_with?("physical")
              phy = ln[/\d+/]
            elsif ln.start_with?("core")
              cid = phy + ":" + ln[/\d+/]
              cores[cid] = true if not cores[cid]
            end
          end
          cores.count
        when /mswin|mingw/
          require 'win32ole'
          result_set = WIN32OLE.connect("winmgmts://").ExecQuery(
            "select NumberOfCores from Win32_Processor")
          result_set.to_enum.collect(&:NumberOfCores).reduce(:+)
        else
          processor_count
        end
        # fall back to logical count if physical info is invalid
        ppc > 0 ? ppc : processor_count
      end
    end
  end
end

module Parallel
  VERSION = Version = '1.10.0'
end

module Parallel
  extend Parallel::ProcessorCount

  class DeadWorker < StandardError
  end

  class Break < StandardError
  end

  class Kill < StandardError
  end

  class UndumpableException < StandardError
    def initialize(original)
      super "#{original.class}: #{original.message}"
      @bracktrace = original.backtrace
    end

    def backtrace
      @bracktrace
    end
  end

  Stop = Object.new

  class ExceptionWrapper
    attr_reader :exception
    def initialize(exception)
      @exception =
        begin
          Marshal.dump(exception) && exception
        rescue
          UndumpableException.new(exception)
        end
    end
  end

  class Worker
    attr_reader :pid, :read, :write
    attr_accessor :thread
    def initialize(read, write, pid)
      @read, @write, @pid = read, write, pid
    end

    def stop
      close_pipes
      wait # if it goes zombie, rather wait here to be able to debug
    end

    # might be passed to started_processes and simultaneously closed by another thread
    # when running in isolation mode, so we have to check if it is closed before closing
    def close_pipes
      read.close unless read.closed?
      write.close unless write.closed?
    end

    def work(data)
      begin
        Marshal.dump(data, write)
      rescue Errno::EPIPE
        raise DeadWorker
      end

      result = begin
        Marshal.load(read)
      rescue EOFError
        raise DeadWorker
      end
      raise result.exception if ExceptionWrapper === result
      result
    end

    private

    def wait
      Process.wait(pid)
    rescue Interrupt
      # process died
    end
  end

  class JobFactory
    def initialize(source, mutex)
      @lambda = (source.respond_to?(:call) && source) || queue_wrapper(source)
      @source = source.to_a unless @lambda # turn Range and other Enumerable-s into an Array
      @mutex = mutex
      @index = -1
      @stopped = false
    end

    def next
      if producer?
        # - index and item stay in sync
        # - do not call lambda after it has returned Stop
        item, index = @mutex.synchronize do
          return if @stopped
          item = @lambda.call
          @stopped = (item == Parallel::Stop)
          return if @stopped
          [item, @index += 1]
        end
      else
        index = @mutex.synchronize { @index += 1 }
        return if index >= size
        item = @source[index]
      end
      [item, index]
    end

    def size
      if producer?
        Float::INFINITY
      else
        @source.size
      end
    end

    # generate item that is sent to workers
    # just index is faster + less likely to blow up with unserializable errors
    def pack(item, index)
      producer? ? [item, index] : index
    end

    # unpack item that is sent to workers
    def unpack(data)
      producer? ? data : [@source[data], data]
    end

    private

    def producer?
      @lambda
    end

    def queue_wrapper(array)
      array.respond_to?(:num_waiting) && array.respond_to?(:pop) && lambda { array.pop(false) }
    end
  end

  class UserInterruptHandler
    INTERRUPT_SIGNAL = :SIGINT

    class << self
      # kill all these pids or threads if user presses Ctrl+c
      def kill_on_ctrl_c(pids, options)
        @to_be_killed ||= []
        old_interrupt = nil
        signal = options.fetch(:interrupt_signal, INTERRUPT_SIGNAL)

        if @to_be_killed.empty?
          old_interrupt = trap_interrupt(signal) do
            $stderr.puts 'Parallel execution interrupted, exiting ...'
            @to_be_killed.flatten.each { |pid| kill(pid) }
          end
        end

        @to_be_killed << pids

        yield
      ensure
        @to_be_killed.pop # do not kill pids that could be used for new processes
        restore_interrupt(old_interrupt, signal) if @to_be_killed.empty?
      end

      def kill(thing)
        Process.kill(:KILL, thing)
      rescue Errno::ESRCH
        # some linux systems already automatically killed the children at this point
        # so we just ignore them not being there
      end

      private

      def trap_interrupt(signal)
        old = Signal.trap signal, 'IGNORE'

        Signal.trap signal do
          yield
          if old == "DEFAULT"
            raise Interrupt
          else
            old.call
          end
        end

        old
      end

      def restore_interrupt(old, signal)
        Signal.trap signal, old
      end
    end
  end

  class << self
    def in_threads(options={:count => 2})
      count, _ = extract_count_from_options(options)
      Array.new(count) do |i|
        Thread.new { yield(i) }
      end.map!(&:value)
    end

    def in_processes(options = {}, &block)
      count, options = extract_count_from_options(options)
      count ||= processor_count
      map(0...count, options.merge(:in_processes => count), &block)
    end

    def each(array, options={}, &block)
      map(array, options.merge(:preserve_results => false), &block)
      array
    end

    def each_with_index(array, options={}, &block)
      each(array, options.merge(:with_index => true), &block)
    end

    def map(source, options = {}, &block)
      options[:mutex] = Mutex.new

      if RUBY_PLATFORM =~ /java/ and not options[:in_processes]
        method = :in_threads
        size = options[method] || processor_count
      elsif options[:in_threads]
        method = :in_threads
        size = options[method]
      else
        method = :in_processes
        if Process.respond_to?(:fork)
          size = options[method] || processor_count
        else
          warn "Process.fork is not supported by this Ruby"
          size = 0
        end
      end

      job_factory = JobFactory.new(source, options[:mutex])
      size = [job_factory.size, size].min

      options[:return_results] = (options[:preserve_results] != false || !!options[:finish])
      add_progress_bar!(job_factory, options)

      if size == 0
        work_direct(job_factory, options, &block)
      elsif method == :in_threads
        work_in_threads(job_factory, options.merge(:count => size), &block)
      else
        work_in_processes(job_factory, options.merge(:count => size), &block)
      end
    end

    def map_with_index(array, options={}, &block)
      map(array, options.merge(:with_index => true), &block)
    end

    def worker_number
      Thread.current[:parallel_worker_number]
    end

    def worker_number=(worker_num)
      Thread.current[:parallel_worker_number] = worker_num
    end

    private

    def add_progress_bar!(job_factory, options)
      if progress_options = options[:progress]
        raise "Progressbar can only be used with array like items" if job_factory.size == Float::INFINITY
        require 'ruby-progressbar'

        if progress_options == true
          progress_options = { title: "Progress" }
        elsif progress_options.respond_to? :to_str
          progress_options = { title: progress_options.to_str }
        end

        progress_options = {
          total: job_factory.size,
          format: '%t |%E | %B | %a'
        }.merge(progress_options)

        progress = ProgressBar.create(progress_options)
        old_finish = options[:finish]
        options[:finish] = lambda do |item, i, result|
          old_finish.call(item, i, result) if old_finish
          progress.increment
        end
      end
    end

    def work_direct(job_factory, options, &block)
      self.worker_number = 0
      results = []
      while set = job_factory.next
        item, index = set
        results << with_instrumentation(item, index, options) do
          call_with_index(item, index, options, &block)
        end
      end
      results
    ensure
      self.worker_number = nil
    end

    def work_in_threads(job_factory, options, &block)
      raise "interrupt_signal is no longer supported for threads" if options[:interrupt_signal]
      results = []
      results_mutex = Mutex.new # arrays are not thread-safe on jRuby
      exception = nil

      in_threads(options) do |worker_num|
        self.worker_number = worker_num
        # as long as there are more jobs, work on one of them
        while !exception && set = job_factory.next
          begin
            item, index = set
            result = with_instrumentation item, index, options do
              call_with_index(item, index, options, &block)
            end
            results_mutex.synchronize { results[index] = result }
          rescue StandardError => e
            exception = e
          end
        end
      end

      handle_exception(exception, results)
    end

    def work_in_processes(job_factory, options, &blk)
      workers = if options[:isolation]
        [] # we create workers per job and not beforehand
      else
        create_workers(job_factory, options, &blk)
      end
      results = []
      results_mutex = Mutex.new # arrays are not thread-safe
      exception = nil

      UserInterruptHandler.kill_on_ctrl_c(workers.map(&:pid), options) do
        in_threads(options) do |i|
          worker = workers[i]

          begin
            loop do
              break if exception
              item, index = job_factory.next
              break unless index

              if options[:isolation]
                worker = replace_worker(job_factory, workers, i, options, blk)
              end

              worker.thread = Thread.current

              begin
                result = with_instrumentation item, index, options do
                  worker.work(job_factory.pack(item, index))
                end
                results_mutex.synchronize { results[index] = result } # arrays are not threads safe on jRuby
              rescue StandardError => e
                exception = e
                if Parallel::Kill === exception
                  (workers - [worker]).each do |w|
                    w.thread.kill unless w.thread.nil?
                    UserInterruptHandler.kill(w.pid)
                  end
                end
              end
            end
          ensure
            worker.stop if worker
          end
        end
      end

      handle_exception(exception, results)
    end

    def replace_worker(job_factory, workers, i, options, blk)
      # old worker is no longer used ... stop it
      worker = workers[i]
      worker.stop if worker

      # create a new replacement worker
      running = workers - [worker]
      workers[i] = worker(job_factory, options.merge(started_workers: running, worker_number: i), &blk)
    end

    def create_workers(job_factory, options, &block)
      workers = []
      Array.new(options[:count]).each_with_index do |_, i|
        workers << worker(job_factory, options.merge(started_workers: workers, worker_number: i), &block)
      end
      workers
    end

    def worker(job_factory, options, &block)
      child_read, parent_write = IO.pipe
      parent_read, child_write = IO.pipe

      pid = Process.fork do
        self.worker_number = options[:worker_number]

        begin
          options.delete(:started_workers).each(&:close_pipes)

          parent_write.close
          parent_read.close

          process_incoming_jobs(child_read, child_write, job_factory, options, &block)
        ensure
          child_read.close
          child_write.close
        end
      end

      child_read.close
      child_write.close

      Worker.new(parent_read, parent_write, pid)
    end

    def process_incoming_jobs(read, write, job_factory, options, &block)
      until read.eof?
        data = Marshal.load(read)
        item, index = job_factory.unpack(data)
        result = begin
          call_with_index(item, index, options, &block)
        rescue StandardError => e
          ExceptionWrapper.new(e)
        end
        Marshal.dump(result, write)
      end
    end

    def handle_exception(exception, results)
      return nil if [Parallel::Break, Parallel::Kill].include? exception.class
      raise exception if exception
      results
    end

    # options is either a Integer or a Hash with :count
    def extract_count_from_options(options)
      if options.is_a?(Hash)
        count = options[:count]
      else
        count = options
        options = {}
      end
      [count, options]
    end

    def call_with_index(item, index, options, &block)
      args = [item]
      args << index if options[:with_index]
      if options[:return_results]
        block.call(*args)
      else
        block.call(*args)
        nil # avoid GC overhead of passing large results around
      end
    end

    def with_instrumentation(item, index, options)
      on_start = options[:start]
      on_finish = options[:finish]
      options[:mutex].synchronize { on_start.call(item, index) } if on_start
      result = yield
      options[:mutex].synchronize { on_finish.call(item, index, result) } if on_finish
      result unless options[:preserve_results] == false
    end
  end
end

## Parse the GpackRepose file

def parse_gpackrepos()

grepos_file = $SETTINGS["core"]["repofile"]

## Options for YAML File
required_keys = ["url","localdir","branch"]
valid_config = ["remote_key"]


grepos = GitCollection.new()

if !File.exist?(grepos_file)
   raise "File does not exist #{grepos_file}"
end

unlocked = File.exists?(".gpackunlock")

yml_file = YAML.load_file(grepos_file)

yml_file.each do |key,entry|
   if key == "config"
      # Read in config settings
      # Check if the config option is valid
      entry.each do |ckey,centry|
         if !valid_config.index(ckey)
            raise "Error in file '#{grepos_file}'.\n\tError in configuration entry #{key}\n\tConfig option must be one of #{valid_config}"
         end

         case ckey
            when "lock"
               # TODO implement this
            when "remote_key"
               #SSH KEY stuff
               $SETTINGS["ssh"]["key_url"] = centry
         end
         
      end
      
   else
      reponame = key
      
      # Check required keys exist
      if !required_keys.all? {|s| entry.key? s}
         raise "Error in file '#{grepos_file}'.\n\tEntry #{key}\n\tFor a repository these properties are required #{required_keys}"
      end
      
      # Optional Key Parsing
      if entry.key?("lock")
         readonly = entry["lock"]
      else
         readonly = true
      end
      
      new_repo = GitReference.new :url=>entry["url"], :localdir=>entry["localdir"], :branch=>entry["branch"]
      
      if unlocked
         new_repo.readonly = false
      end
      grepos.add_ref(new_repo)
      
   end
end


return grepos

end

def download_ssh_key()
   key_url = $SETTINGS["ssh"]["key_url"]
   if key_url
      remote_key = Tempfile.new('gpack_ssh') # TODO make this readable only by user      
      begin
         download = open(key_url)
         IO.copy_stream(download, remote_key.path)
      rescue
         puts "Error with URL #{key_url}\nEnsure this is a valid url and can be reached"
         raise
      end
      $SETTINGS["ssh"]["key"] = remote_key

   end
end

def set_ssh_cmd()
   remote_key = $SETTINGS["ssh"]["key"] 
   id_cmd = ""
   id_cmd = "-i #{remote_key.path} " if remote_key
   
   ssh_cmd="ssh #{id_cmd}-q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" 

   $SETTINGS["ssh"]["cmd"] = ssh_cmd
   
end

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
  opts.on("-s","--single") do
    $SETTINGS["core"]["parallel"] = false
  end
end.parse!

case ARGV[0]
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
