#!/bin/bash
mkdir -p sub_workflows

#Args
LATEST=$1

cd sub_workflows

while IFS=, read -r repo branch
do
  echo $repo 
  git clone git@github.com:"$repo" --depth 1 -b $branch

  if [ -n "${LATEST}" ]; then
    #If requested, use the latest release rather than main
    cd $(basename $repo)
    git config advice.detachedHead false
    pipeline_tag=$(git describe --tags `git rev-list --tags --max-count=1`)
    git checkout $pipeline_tag
    cd ..
  fi
  echo 
done < "../includerepos.csv"

cd ..