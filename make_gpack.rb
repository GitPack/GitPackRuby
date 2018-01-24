#!/bin/env ruby

$VERBOSE=nil

fname="gpack_concat.rb"

Dir.chdir("./lib") do

#Make the readme

   README="README=%{\n"+File.read("../README.rst")+"\n}\n"
   File.write('./gpack_readme.rb', README)


   `cat headers.rb gpack_readme.rb GitReference.rb GitCollection.rb parallel.rb parse_repos.rb gpack.rb > #{fname}`
end

`mv lib/#{fname} .`
`chmod +x #{fname}`
