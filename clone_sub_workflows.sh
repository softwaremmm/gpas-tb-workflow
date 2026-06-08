#!/bin/bash
mkdir -p sub_workflows

#Args
LATEST=$1

cd sub_workflows


jq -r 'to_entries[] | "\(.key) \(.value)"' ../pipeline_versions.json |
while read repo identififer; do
  echo $repo $identififer
  rm -rf $repo
  echo "Running git@github.com:softwaremmm/"$repo".git"
  git clone git@github.com:softwaremmm/"$repo".git
  cd $repo
  git config advice.detachedHead false
  git checkout $identififer
  cd ..

  if [ -n "${LATEST}" ]; then
    #If requested, use the latest release rather than main
    cd $(basename $repo)
    git config advice.detachedHead false
    pipeline_tag=$(git describe --tags `git rev-list --tags --max-count=1`)
    git checkout $pipeline_tag
    cd ..
  fi
  echo 
done

cd ..