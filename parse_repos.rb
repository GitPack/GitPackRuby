
## Parse the GpackRepose file

def parse_gpackrepos(grepos_file)

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
   else
      reponame = key
      
      # Check required keys exist
      required_keys = ["url","local_dir","branch"]
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
