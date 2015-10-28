#!/usr/bin/env bash

# Usage
# sr-code-style-check.sh <repository path (default: ./src)> <workspace path (default: .)> <code-style-check-type(default: code_style_check)>
#
# Results are written to <workspace>/build/test_results/<package_name> in XML format starting with roslint prefix.
#
# Examples
#
# All default parameters
# ~/workspaces/ros/sr-build-tools/bin/sr-code-style-check.sh
#
# Path to repository files specified
# ~/workspaces/ros/sr-build-tools/bin/sr-code-style-check.sh ~/workspaces/ros/shadow_ws/src/sr-visualization

pushd `dirname $0` > /dev/null
export script_path=`pwd -P`
popd > /dev/null

# Path to workspace. By default current directory
export workspace_path=${2:-`pwd -P`}

# Path to the repository in the workspace. Default ./src
export repo_path=${1:-$workspace_path/src}

# Possible values:
# - code_style_check : checks Python and C++ files (default)
# - cpp_code_style_check : check C++ files only
# - python_code_style_check : check Python files only
export code_style_check_type=${3:-"code_style_check"}

export test_results_dir=$workspace_path/build/test_results

# Ansible need to be installed using pip
# sudo pip install ansible
ansible-playbook -v -i "localhost," -c local $script_path/../ansible/docker_site.yml --skip-tags "shippable" --tags $code_style_check_type -e "repo_sources_path=$repo_path ros_workspace=$workspace_path test_results_dir=$test_results_dir code_coverage_options='' run_install=false "
