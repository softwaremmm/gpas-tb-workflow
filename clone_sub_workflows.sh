#!/bin/bash
mkdir -p sub_workflows

#Args
LATEST=$1

cd sub_workflows

for p in $(cat ../includerepos.txt); do
  echo $p 
  git clone git@github.com:"$p" --depth 1 -b main

  if [ -n "${LATEST}" ]; then
    #If requested, use the latest release rather than main
    cd $(basename $p)
    git config advice.detachedHead false
    pipeline_tag=$(git describe --tags `git rev-list --tags --max-count=1`)
    git checkout $pipeline_tag
    cd ..
  fi
  echo 
done

cd ..