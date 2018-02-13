#!/usr/bin/env ruby 

require 'tempfile'
require 'open3'
require 'yaml'
require 'open-uri'
require 'digest/sha1'
require 'rdoc'
require 'find'
require 'fileutils'
require 'optparse'

begin
  require 'byebug'
rescue LoadError
  # Don't crash if debug gem isn't there
end
