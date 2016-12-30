#!/usr/bin/env bash

set -e # fail on errors
#set -x # echo commands run

export package_directory=$1
export ros_release=${2:-indigo}
export ubuntu_version_name=${3:-trusty}

pushd ${package_directory}

source <(grep '^export\|^source' ~/.bashrc)

bloom-generate rosdebian --os-name ubuntu --os-version ${ubuntu_version_name} --ros-distro ${ros_release} --place-template-files

export git_revision_number=`git rev-list HEAD | wc -l`

grep -rl --include "*.em" "@(change_version)" . | xargs sed -i "s/@(change_version)/@(change_version).${git_revision_number}/g"

bloom-generate rosdebian --os-name ubuntu --os-version ${ubuntu_version_name} --ros-distro ${ros_release} --process-template-files

popd