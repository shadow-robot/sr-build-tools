#!/usr/bin/env bash

# Script is based on http://machineawakening.blogspot.com/2015/05/how-to-download-all-gazebo-models.html

pushd /tmp

wget -l 2 -nc -r "http://models.gazebosim.org/" --accept gz

cd "models.gazebosim.org"

for i in *
do
  tar -zvxf "$i/model.tar.gz"
done

mkdir -p "$HOME/.gazebo/models/"
cp -vfR * "$HOME/.gazebo/models/"

rm -rf "models.gazebosim.org"

popd