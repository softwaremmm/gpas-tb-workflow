mkdir -p sub_workflows

while read p; do
  git -C sub_workflows clone git@github.com:"$p" --depth 1 -b main 
done <includerepos.txt