# sr-code-style-check.sh

## Setup

You need to install Ansible in order to run this script.

Use following command to do so (it will install recent version in contrary to apt-get) 

```bash
sudo pip install ansible
```

## Usage

```bash
sr-code-style-check.sh <repository path (default: ./src)> <workspace path (default: .)> <code-style-check-type(default: code_style_check)>
```

## Results 

The results are written to *&lt;workspace&gt;/build/test_results/&lt;package_name&gt;* in XML format starting with *roslint* prefix.

## Examples

### All default parameters
```bash
 ~/workspaces/ros/sr-build-tools/bin/sr-code-style-check.sh
```

### Path to repository files and workspace specified
```bash
~/workspaces/ros/sr-build-tools/bin/sr-code-style-check.sh ~/workspaces/ros/shadow_ws/src/sr-visualization ~/workspaces/ros/shadow_ws
```
