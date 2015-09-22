# Ansible

Ansible roles for installing generic ROS things as well as specific Shadow projects.

Also contains the playbook (vagrant_site.yaml) used for provisioning the Vagrant virtual machines.

## Continous Integration servers 
The extra roles were added to run builds and different checks of the project on the hosted servers.
The main playbook for these tasks is [docker_site.yml](./docker_site.yml).

More details can be found [here](roles/ci/doc/README.md)
