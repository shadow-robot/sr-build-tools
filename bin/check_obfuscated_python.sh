count=0
folders_to_check="/opt/ros /home/user"
for folder in $folders_to_check; do
  python_files=()
  python_files=($(find $folder -type f -path "*sr_*" -not -name '*.py' -exec grep -R -I -P '^#!/usr/bin/env python|^#! /usr/bin/env python|^#!/usr/bin/python|^#! /usr/bin/python' -l {} \;))
  python_files+=($(find $folder -type f -path "*sr_*" -name '*.py' -not -name "*pc.py"))
  for file in "${python_files[@]}"
  do
      check=$(cat $file | grep "__pyarmor__")
      if [[ "$check" == "" ]]; then
          echo "Not pyarmored: $file"
          count=$count+1
      fi
  done
done
if $count>0;then
  echo "$count non-pyarmored python files found, please check them manually to make sure they are not sensitive"
else
  echo "All senstivite python files are pyarmored"
fi
