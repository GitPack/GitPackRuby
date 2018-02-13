
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
   
   if remote_key
      id_arg = " -i #{remote_key.path}" 

      ssh_cmd=$SETTINGS["ssh"]["cmd"]
      if $SETTINGS["ssh"]["cmd"]
         ssh_cmd="#{ssh_cmd}#{id_arg}" 
      else
         ssh_cmd="ssh #{id_arg}"
      end
      $SETTINGS["ssh"]["cmd"] = ssh_cmd
   end
   
end
