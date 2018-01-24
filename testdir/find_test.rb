require 'find'
require 'fileutils'

file_paths = []
ignore_paths = []
Find.find('repos/test1') do |path|
if path.match(/.*\/.git$/) || path.match(/.*\/.git\/.*/)
   ignore_paths << path
else
   file_paths << path
   #FileUtils.chmod 'a-w', path
   FileUtils.chmod 'u+w',path
end
end


puts "IGNORED PATHS\n"+ignore_paths.to_s
puts "FOUND_PATHS\n"+file_paths.to_s
