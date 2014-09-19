RoNeX Indigo Developer
======================

RoNeX development machine, ROS Indigo on Ubuntu Trusty. Start machine with:
```sh
cd sr-build-tools/vagrant/dev/ronex-indigo
vagrant up
==> ronex-indigo: Available bridged network interfaces:
1) eth0
2) eth1
```
Note the prompt, you should select the ethernet card you are going to attach the ronex to here. Machine gets a bridged network on that device.

After a while you should have a vm desktop with a `ronex` user (password password), indigo-devel branch checked out and built in `~/indigo_ws/`.

Machine has 2 network adapters, eth0 is a nat connection so the machine can see the internet, eth1 is a bridged adapter
to connect EtherCAT devices to, eth2 is a local network
you can use to access the machine with ssh.
