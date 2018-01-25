#!/bin/env ruby

$VERBOSE=nil

fname="gpack_concat.rb"
fname_custom="gpack_concat_custom.rb"

custom_build = false

Dir.chdir("./lib") do

#Make the readme

   custom_build = true if File.exist?("headers_custom.rb")

   README="README=%{\n"+File.read("../README.rst")+"\n}\n"
   File.write('./gpack_readme.rb', README)

   `cat headers.rb gpack_readme.rb GitReference.rb GitCollection.rb parallel.rb parse_repos.rb ssh.rb gpack.rb > #{fname}`
   `cat headers_custom.rb gpack_readme.rb GitReference.rb GitCollection.rb parallel.rb parse_repos.rb ssh.rb gpack.rb > #{fname_custom}` if custom_build

end

puts "Custom Build" if custom_build

`mv lib/#{fname} .`
`mv lib/#{fname_custom} .` if custom_build
`chmod +x #{fname}`
`chmod +x #{fname_custom}` if custom_build
