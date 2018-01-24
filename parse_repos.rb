
## Parse the GpackRepose file

def parse_gpackrepos(grepos_file)


## Options for YAML File
required_keys = ["url","local_dir","branch"]
valid_config = ["lock","remote_key","parallel"]


grepos = GitCollection.new()

if !File.exist?(grepos_file)
   raise "File does not exist #{grepos_file}"
end

unlocked = File.exists?(".gpackunlock")

yml_file = YAML.load_file(grepos_file)

yml_file.each do |key,entry|
   puts "#{key} #{entry}"
   if key == "config"
      # Read in config settings
      puts "CONFIG"
      # Check if the config option is valid
      entry.each do |ckey,centry|
         if !valid_config.index(ckey)
            raise "Error in file '#{grepos_file}'.\n\tError in configuration entry #{key}\n\tConfig option must be one of #{valid_config}"
         end

         case ckey
         
            when "parallel"
               $use_parallel = centry
            when "lock"
               
            when "remote_key"
               #SSH KEY stuff
               key_url = centry
               $remote_key = Tempfile.new('gpack_ssh')
               #`wget -O #{$remote_key.path} #{key_url} &> /dev/null`
               
               begin
                  download = open(key_url)
                  IO.copy_stream(download, $remote_key.path)
               rescue
                  puts "Error with URL #{key_url}\nEnsure this is a valid url and can be reached"
                  raise
               end
               $GIT_SSH_COMMAND="ssh -i #{$remote_key.path} -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" 
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
      
      new_repo = GitReference.new :url=>entry["url"], :localdir=>entry["local_dir"], :branch=>entry["branch"]
      
      if unlocked
         new_repo.readonly = false
      end
      grepos.add_ref(new_repo)
      
   end
end


return grepos

end
