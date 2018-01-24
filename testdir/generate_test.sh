#!/bin/bash

# This script creates some dummy commits to test the gpack update

wdir=$PWD

if false
then

rm testrepos/TestRepo1 -rf
git clone git@github.com:GitPack/TestRepo1.git ./testrepos/TestRepo1 --recursive

echo $RANDOM > testrepos/TestRepo1/dummy1.txt
echo $RANDOM > testrepos/TestRepo1/TestRepo2/dummy2.txt

cd $wdir/testrepos/TestRepo1/TestRepo2
pwd
git checkout master
git add .
git commit -m  "Test commit"
git push
git status

cd $wdir/testrepos/TestRepo1
pwd
git add .
git commit -m  "Test commit"
git push
git status

fi




################# CREATE SOME CHANGES IN GpackRepos


echo $RANDOM > ./repos/test1/dummy1.txt # New file
echo $RANDOM > ./repos/test1/README.md # Change file
echo $RANDOM > ./repos/test1/TestRepo2/README.md # New file submodule
echo $RANDOM > ./repos/test1/TestRepo2/newfile.txt # Change file submodule
