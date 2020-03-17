
def gpack_prompt()

require 'timeout'

skip_gpack = false
if File.file?('.gpackskip')
   puts "Found local file .gpackskip, remove this to enable gpack"
   skip_gpack = true
end


# Check if .gpack_skip exists in the workarea

if !skip_gpack
puts "Update/Install project git repositories using gpack?\nTHIS WILL IMPACT ON NETWORK USAGE IF REPOSITORY IS LARGE\n(y|enter,n,never,always)".color(Colors::RED)

begin
answer = Timeout::timeout(10) do
$stdin.gets
end
rescue Timeout::Error
puts "Timeout Occured, skipping gpack"
answer = 'no'
end


if ["y","yes",""].include? answer.downcase.chomp
   puts "Running Gpack"
else
   skip_gpack=true
end

if ["never"].include? answer.downcase.chomp
   puts "Always skipping, creating file .gpackskip"
   `touch .gpackskip`
end

end

if skip_gpack
   puts "Skipping Gpack Execution"
   exit
end

end
