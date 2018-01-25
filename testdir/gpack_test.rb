#!/bin/env ruby

current_file = File.dirname(__FILE__)

lib_path = current_file+"/../lib"

begin
  require 'byebug'
rescue LoadError
  # Don't crash if debug gem isn't there
end

load lib_path+"/headers.rb"
load lib_path+"/gpack_readme.rb"
load lib_path+"/GitReference.rb"
load lib_path+"/GitCollection.rb"
load lib_path+"/parallel.rb"
load lib_path+"/parse_repos.rb"
load lib_path+"/ssh.rb"
load lib_path+"/gpack.rb"
