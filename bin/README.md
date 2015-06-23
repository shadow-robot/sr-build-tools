# sr-code-style-check.sh

## Setup

You need to install Ansible in order to run this script.

Use following command to do so (it will install recent version in contrary to apt-get) 

```bash
sudo pip install ansible
```

## Usage

```bash
sr-code-style-check.sh <project path (default: ./src)> <workspace path (default: .)> <code-style-check-type(default: code_style_check)>
```

## Results 

The results are written to *<workspace>/build/test_results/<package_name>* in XML format starting with *roslint* prefix.

## Examples

### All default parameters
```bash
 ~/workspaces/ros/sr-build-tools/bin/sr-code-style-check.sh
```

### Path to project files and workspace specified
```bash
~/workspaces/ros/sr-build-tools/bin/sr-code-style-check.sh ~/workspaces/ros/shadow_ws/src/sr-visualization ~/workspaces/ros/shadow_ws
```
