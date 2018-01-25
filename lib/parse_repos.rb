
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
