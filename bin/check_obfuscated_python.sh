unarmored_count=0
armored_count=0
folders_to_check="/opt/ros"
for folder in $folders_to_check; do
  python_files=()
  python_files=($(find $folder -type f -path "*sr_*" -not -name '*.py' -exec grep -R -I -P '^#!/usr/bin/env python|^#! /usr/bin/env python|^#!/usr/bin/python|^#! /usr/bin/python' -l {} \;))
  python_files+=($(find $folder -type f -path "*sr_*" -name '*.py' -not -name "*.pc.py" -not -name "*__init__.py*"))
  for file in "${python_files[@]}"
  do
      check=$(cat $file | grep "__pyarmor__")
      if [[ "$check" == "" ]]; then
          echo "Not pyarmored: $file"
          ((unarmored_count++))
      else
          ((armored_count++))
      fi
  done
done
if [ $unarmored_count -gt 0 ];then
  echo "$unarmored_count non-pyarmored python files found, please check them manually to make sure they are not sensitive. $armored_count pyarmored files found."
else
  echo "All senstivite python files are pyarmored. $armored_count pyarmored files found."
fi
