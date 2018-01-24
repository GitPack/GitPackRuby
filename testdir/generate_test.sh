#!/bin/bash

wdir=$PWD

echo $RANDOM > testrepos/TestRepo1/dummy1.txt
echo $RANDOM > testrepos/TestRepo1/TestRepo2/dummy2.txt

cd $wdir/testrepos/TestRepo1/TestRepo2
pwd
git checkout master
git add .
git commit -m  "Test commit"
git push

cd $wdir/testrepos/TestRepo1
pwd
git add .
git commit -m  "Test commit"
git push
