
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
         puts "Reference #{ref.url}\n\tlocaldir-#{ref.localdir}\n\tbranch-#{ref.branch}\n\treadonly-#{ref.readonly}"
      end
   end
   def archive()
      puts "\nCreating archives of local Repositories....."
      raise_warning = ref_loop(refs) { |ref|
         ref.archive
      }
      if raise_warning
         puts ("\n"+"="*60+"\nWARNING DURING CLONING!\n\tSome repositories already existed and failed checks.\n\tReview this log or run 'gpack check' to see detailed information\n"+"="*60).color(Colors::RED)
      end
   end   
   def clone()
      puts "\nCloning Repositories....."
      raise_warning = ref_loop(refs) { |ref|
         ref.clone
      }
      if raise_warning
         puts ("\n"+"="*60+"\nWARNING DURING CLONING!\n\tSome repositories already existed and failed checks.\n\tReview this log or run 'gpack check' to see detailed information\n"+"="*60).color(Colors::RED)
      end
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
   def reinstall()
      puts "This will force remove repositories and repopulate. Any local data will be lost!!!\nContinue (y/n)"
      cont = $stdin.gets.chomp
      if cont == "y"
         puts "Forcing Clean"
         remove(true)
         clone()
         set_writeable(false)
      else
         puts "Abort Clean"
      end
   
   end
   def check()
      puts "\nChecking Local Repositories....."
      raise_warning = ref_loop(refs,true) { |ref|
         ref.check
      }
      if raise_warning
         puts ("\n"+"="*60+"\nWARNINGS FOUND DURING CHECK!\n\tReview this log to see detailed information\n"+"="*60).color(Colors::RED)
      end
   end
   def status()
      puts "\nStatus of Local Repositories....."
      raise_warning = ref_loop(refs,true) { |ref|
         ref.status
      }
      if raise_warning
         puts ("\n"+"="*60+"\nWARNINGS FOUND DURING CHECK!\n\tReview this log to see detailed information\n"+"="*60).color(Colors::RED)
      end
   end
   def update(force_clone=false)
      puts "\nUpdating Repositories.....\n\n"
      puts "Please be patient, this can take some time if pulling large commits.....".color(Colors::GREEN)
      raise_warning = ref_loop(refs) { |ref|
         ref.update(force_clone)
      }
      if raise_warning
         puts ("\n"+"="*60+"\nWARNING DURING UPDATE!\n\tSome repositories failed checks and were not updated.\n\tReview this log or run 'gpack check' to see detailed information\n"+"="*60).color(Colors::RED)
      end
   end
   def remove(force=false)
      puts "\nRemoving Local Repositories....."
      raise_warning = ref_loop(refs) { |ref|
         ref.remove(force)
      }
      if raise_warning
         puts ("\n"+"="*60+"\nWARNINGS FOUND DURING REMOVAL!\n\tReview this log to see detailed information\n"+"="*60).color(Colors::RED)
      end
   end
   def set_writeable(tf)
      ref_loop(refs) { |ref|
         ref.set_writeable(tf)
      }
   end
   
   
   def ref_loop(refs, parallel_override=false)
      if $use_parallel && !parallel_override
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

