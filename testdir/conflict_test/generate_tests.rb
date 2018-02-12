#!/usr/bin/env ruby

require 'byebug'
require 'open3'

$VERBOSE=nil

puts `rm -rf ./testrepo_*`
$testrepo="git@github.com:GitPack/TestRepo3.git"

$logfile = File.open("./testlog.txt","w")


def cmd(cmd_str,logfile=false)
   puts cmd_str   
   stdout_str, status = Open3.capture2e(cmd_str)
   puts stdout_str
   if logfile
      logfile.puts(stdout_str)
      logfile.puts("Success=#{status.success?}")
   end
   return status.success?
end


def repo_loop(test,repolist,chdir=true)
for repo in repolist do
   id = "#{test}#{repo}"
   r = { \
      'id' => id, \
      'dest' => "./testrepo_#{id}", \
      'bname' => "testbranch_#{id}", \
      'repo' => repo, \
      'test' => test
      }
   Dir.chdir(r['dest']) if chdir
   yield(r)
   Dir.chdir("../")
end
end

def try_merge(test)
# Go into repo A and pull repo B
repo_loop(test,["A"]) { |r|
   puts `git fetch origin`
   branch2 = "origin/testbranch_#{test}B"
   
   $logfile.puts("===========TEST #{test}==========")
   status=cmd("git format-patch $(git merge-base HEAD #{branch2})..#{branch2} --stdout | git apply --check -",$logfile)
   puts "TEST #{test} SUCCESS=#{status}"
}
end


repolist = ["A","B"]

# ==================TEST 1==================
# Normal Merge

test = "1"

repo_loop(test,repolist,false) { |r|

   puts `git clone #{$testrepo} #{r['dest']}`
   
   Dir.chdir(r['dest'])

   cmd "git checkout -b #{r['bname']}"

   # Generate the test
   teststr = "Test #{r['test']} repo#{r['repo']}"
   cmd "echo '#{teststr}'> README#{r['repo']}.md"
   cmd "git add . && git commit -a -m '#{teststr}'"
   
   cmd "git push -f origin #{r['bname']}"
   
   
}

# Merge should pass
try_merge(test)

# ==================TEST 2==================
# Conflicted File

test = "2"

repo_loop(test,repolist,false) { |r|

   puts `git clone #{$testrepo} #{r['dest']}`
   
   Dir.chdir(r['dest'])

   cmd "git checkout -b #{r['bname']}"

   # Generate the test
   teststr = "Test #{r['test']} repo#{r['repo']}"
   cmd "echo '#{teststr}'> README.md"
   cmd "git add . && git commit -a -m '#{teststr}'"
   
   cmd "git push -f origin #{r['bname']}"
   
}

# Merge should fail
try_merge(test)

# ==================TEST 3==================
# File created in A, but not commited, merged from B

test = "3"

repo_loop(test,repolist,false) { |r|

   puts `git clone #{$testrepo} #{r['dest']}`
   
   Dir.chdir(r['dest'])

   cmd "git checkout -b #{r['bname']}"

   # Generate the test
   teststr = "Test #{r['test']} repo#{r['repo']}"
   for filenum in 1..10 # Make a bunch of files just to see what the patch looks like
      cmd "echo '#{teststr}'> README_#{test}_#{filenum}.md"
   end
   if r['repo'] == "B"
      cmd "git add . && git commit -a -m '#{teststr}'"
      cmd "git push -f origin #{r['bname']}"
   end
   
}

# Merge should fail
try_merge(test)

# ==================TEST 4==================
# File removed in A, modified in B

test = "4"

repo_loop(test,repolist,false) { |r|

   puts `git clone #{$testrepo} #{r['dest']}`
   
   Dir.chdir(r['dest'])

   cmd "git checkout -b #{r['bname']}"

   # Generate the test
   teststr = "Test #{r['test']} repo#{r['repo']}"
   case r['repo']
      when "A"
         cmd("rm ./README.md")
      when "B"
         cmd "echo '#{teststr}'> README.md"
   end

   cmd "git add . && git commit -a -m '#{teststr}'"
   cmd "git push -f origin #{r['bname']}"
   
   
}

# Merge should fail
try_merge(test)

# ==================TEST 5==================
# File modified in A, removed in B

test = "5"

repo_loop(test,repolist,false) { |r|

   puts `git clone #{$testrepo} #{r['dest']}`
   
   Dir.chdir(r['dest'])

   cmd "git checkout -b #{r['bname']}"

   # Generate the test
   teststr = "Test #{r['test']} repo#{r['repo']}"
   case r['repo']
      when "A"
         cmd "echo '#{teststr}'> README.md"
      when "B"
         cmd("rm ./README.md")
   end

   cmd "git add . && git commit -a -m '#{teststr}'"
   cmd "git push -f origin #{r['bname']}"
   
   
}

# Merge should fail
try_merge(test)

# ==================cleanup==================


$logfile.close
