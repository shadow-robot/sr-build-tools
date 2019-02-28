#!/usr/bin/env bash

set -e # fail on errors
# set -x # echo commands run

temp_dir="$(mktemp -d)"
wget -O "${temp_dir}/code.deb" 'https://go.microsoft.com/fwlink/?LinkID=760868'
sudo apt update
sudo apt install -y "${temp_dir}/code.deb"
rm -rf "${temp_dir}"
