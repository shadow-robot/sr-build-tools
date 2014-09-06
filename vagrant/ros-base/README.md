Shadow Vagrant
==============

Machines used make [ROS](http://ros.org) [Vagrant](http://vagrantup.com) base images that take a basic ubuntu base, add the desktop system and a full ROS desktop install.

Note this is a multi machine vagrant setup, with a machine for each ubuntu version.

## Building a base image

List machines:
```sh
cd sr-build-tools/vagrant/ros-base
vagrant status
```

Pick a machine to build from the list, e.g. indigo on trusty:
```sh
vagrant up ros-indigo-desktop-trusty64
```
Now go make tea, this takes a while...

Once that builds restart the machine to bring up the newly installed GUI up:

```sh
vagrant halt ros-indigo-desktop-trusty64
vagrant up ros-indigo-desktop-trusty64
```

You may get an error about failing to mount folders, this is because the guest additions will need updating. You should do this anyway even without the error.

* Log into the machine as the vagrant user (password vagrant)
* Select Devices -> Install Guest Additions CD Image on the virtual box window.
* Click yes for the autorun prompt.

Now shutdown the machine (vagrant halt) and open up it's settings in virtual box and remove all the shared folders, make sure no CDs are mounted and any final cleanup. Then create the new box file for the machine (you can get the name from the vbox settings window).
```sh
vagrant package --base ros-indigo-desktop-trusty64_default_1394020834281_59005
```
If all went well you can now install that image with:
```sh
vagrant box add ros-indigo-desktop-trusty64 package.box
```

## Test the base image

```sh
mkdir ~/rosvm
cd ~/rosvm
vagrant init ros-indigo-desktop-trusty64
sed -i.bak 's/#   vb.gui = true/    vb.gui = true/' Vagrantfile  # Open VM desktop
vagrant up
```
