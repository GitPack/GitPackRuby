#!/bin/env ruby

$VERBOSE=nil

fname="gpack_concat.rb"
fname_custom="./GitPackRubyCustom/gpack.rb"

custom_build = false

Dir.chdir(".") do

#Make the readme

   README="README=%{\n"+File.read("./README.rst")+"\n}\n"
   File.write('./lib/gpack/core/gpack_readme.rb', README)

   `cat ./concat/gpack_header.rb ./lib/gpack/*/*.rb ./concat/gpack_footer.rb > #{fname}`
   `cat ./concat/gpack_header.rb ./GitPackRubyCustom/headers_custom.rb ./lib/gpack/core/*.rb ./concat/gpack_footer.rb > #{fname_custom}`

end

`chmod +x #{fname}`
`chmod +x #{fname_custom}`
