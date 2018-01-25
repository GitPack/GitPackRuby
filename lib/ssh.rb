
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
