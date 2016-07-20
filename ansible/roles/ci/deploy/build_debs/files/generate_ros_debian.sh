#!/usr/bin/env bash

set -e # fail on errors
set -x # echo commands run

export ros_release=${1:-indigo}

source <(grep '^export\|^source' ~/.bashrc)

bloom-generate rosdebian --os-name ubuntu --os-version trusty --ros-distro ${ros_release} --place-template-files

export git_revision_number=`git rev-list HEAD | wc -l`

grep -rl --include "*.em" "@(change_version)" . | xargs sed -i "s/@(change_version)/@(change_version).${git_revision_number}/g"

bloom-generate rosdebian --os-name ubuntu --os-version trusty --ros-distro ${ros_release} --process-template-files
