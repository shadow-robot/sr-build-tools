# Ansible

Ansible roles for installing generic ROS things as well as specific Shadow projects.

Also contains the playbook (vagrant_site.yaml) used for provisioning the Vagrant virtual machines.

## Setting up a production machine
To install a new machine, follow those steps:
 - Run a standard ubuntu 14.04 installation, creating a user **administration**
 - Then run the following command, **replacing** `shadowrobot_1234` with the name of the branch you want to use (it will create it if it doesn't exist, get it otherwise):
```
curl https://raw.githubusercontent.com/shadow-robot/sr-build-tools/indigo-devel/bin/setup_production_machine | bash -s shadowrobot_1234
```

## Continous Integration servers 
The extra roles were added to run builds and different checks of the project on the hosted servers.
The main playbook for these tasks is (docker_site.yml).

More details can be found [here](roles/ci/doc)
