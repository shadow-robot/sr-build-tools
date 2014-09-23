Shadow Hand Indigo Developer
============================

Shadow Hand development (src) machine, ROS Indigo on Ubuntu Trusty. Start machine with:
```sh
cd sr-build-tools/vagrant/dev/hand-indigo
vagrant up
```
After a while you should have a vm desktop with a `hand` user (password hand), indigo-devel branch checked out and built in `~/indigo_ws/`.

Machine has 2 network adapters, eth0 is a nat connection so the machine can see the internet, eth1 is a local network
you can use to access the machine with ssh.
