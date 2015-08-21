# Ansible

Ansible roles for installing generic ROS things as well as specific Shadow projects.

Also contains the playbook (vagrant_site.yaml) used for provisioning the Vagrant virtual machines.

## Setting up a production machine
To install a new machine, follow those steps:
 - Run a standard ubuntu 14.04 installation, creating a user **administration**
 - The run the following command: 
```
source <(curl -s https://raw.githubusercontent.com/shadow-robot/sr-build-tools/indigo-devel/bin/setup_production_machine)
```
