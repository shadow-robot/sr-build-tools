# Ansible

Ansible roles for installing generic ROS things as well as specific Shadow projects.

Also contains the playbook (vagrant_site.yaml) used for provisioning the Vagrant virtual machines.

## Setting up a production machine
Here are the steps to setup a new production machine:
 - Install Ubuntu Trusty 64 bits. Create a user named **administrator**.
 - Install ansible and git: `sudo apt-get install -y ansible git`
 - Get sr-build-tools: `git clone https://github.com/shadow-robot/sr-build-tools`
 - Edit `/etc/ansible/hosts` and add the lines: 
```
[hand-prod]
localhost ansible_connection=local
```
 - Run the playbook to install everything: `ansible-playbook -v -K sr-build-tools/ansible/vagrant_site.yml`
