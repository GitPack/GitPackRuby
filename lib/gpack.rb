require 'tempfile'
require 'open3'
require 'yaml'
require 'open-uri'
require 'digest/sha1'
require 'rdoc'
require 'find'
require 'fileutils'
require 'optparse'
require 'timeout'

begin
  require 'byebug'
rescue LoadError
  # Don't crash if debug gem isn't there
end

require "gpack/config/headers.rb"
require "gpack/core/gpack_readme.rb"
require "gpack/core/prompt.rb"
require "gpack/core/GitReference.rb"
require "gpack/core/GitCollection.rb"
require "gpack/core/parallel.rb"
require "gpack/core/parse_repos.rb"
require "gpack/core/ssh.rb"
require "gpack/core/gpack.rb"
