#!/bin/env ruby
$VERBOSE=nil

require 'open3'
load 'parallel.rb'


repo_list = ['git@nhlinear.eng.allegro.msad:ast/clio-template.git','git@nhlinear.eng.allegro.msad:ast/71240.git']




def repo_loop(list)
   threads = []
   list.each do |elem|
      threads << Thread.new{
         yield elem
      }
   end
   ThreadsWait.all_waits(*threads)
end


#repo_loop(repo_list) {|elem| puts `git clone #{elem}`}



results = Parallel.map(repo_list) do |elem|

   # Set up standard output as a StringIO object.
   old_stdout = $stdout
   foo = StringIO.new
   $stdout = foo

   cmd = "git clone #{elem}"
   puts "#{cmd}"
   stdout_str,stderr_str,status = Open3.capture3(cmd)
   #puts stdout_str
   if status == 0
      puts stderr_str
      puts stdout_str
   else
      puts stderr_str
      puts stdout_str
   end
   
   $stdout = old_stdout
   puts foo.string
   
end
