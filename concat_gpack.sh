#!/bin/bash
fname=gpack_concat.rb
cat headers.rb gpack_readme.rb GitReference.rb GitCollection.rb parallel.rb gpack.rb > $fname
chmod +x $fname
