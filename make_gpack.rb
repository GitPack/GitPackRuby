#!/bin/env ruby

$VERBOSE=nil

fname="gpack_concat.rb"

#Make the readme

README="README=%{\n"+File.read("./README.rst")+"\n}"
File.write('./gpack_readme.rb', README)


`cat headers.rb gpack_readme.rb GitReference.rb GitCollection.rb parallel.rb gpack.rb > #{fname}`
`chmod +x #{fname}`
