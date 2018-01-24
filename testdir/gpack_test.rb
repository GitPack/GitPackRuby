#!/bin/env ruby

current_file = File.dirname(__FILE__)

begin
  require 'byebug'
rescue LoadError
  # Don't crash if debug gem isn't there
end

load current_file+"/../headers.rb"
load current_file+"/../gpack_readme.rb"
load current_file+"/../GitReference.rb"
load current_file+"/../GitCollection.rb"
load current_file+"/../parallel.rb"
load current_file+"/../parse_repos.rb"
load current_file+"/../gpack.rb"
