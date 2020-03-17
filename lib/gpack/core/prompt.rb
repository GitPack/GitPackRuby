
def gpack_prompt()

require 'timeout'

skip_gpack = false
if File.file?('.gpackskip')
   puts "Found local file .gpackskip, remove this to enable gpack".color(Colors::YELLOW)
   skip_gpack = true
end


# Check if .gpack_skip exists in the workarea

if !skip_gpack
puts "Update/Install project git repositories using gpack?\nTHIS WILL IMPACT ON NETWORK USAGE IF REPOSITORY IS LARGE\n(y|yes|enter , n|no , never)".color(Colors::RED)

begin
answer = Timeout::timeout(10) do
$stdin.gets
end
rescue Timeout::Error
puts "Timeout Occured, skipping gpack".color(Colors::GREEN)
answer = 'no'
end


if ["y","yes",""].include? answer.downcase.chomp
   puts "Running Gpack".color(Colors::GREEN)
else
   skip_gpack=true
end

if ["never"].include? answer.downcase.chomp
   puts "Always skipping, creating file .gpackskip".color(Colors::GREEN)
   `touch .gpackskip`
end

end

if skip_gpack
   puts "Skipping Gpack Execution".color(Colors::GREEN)
   exit
end

end
