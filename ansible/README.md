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

 - In the [sr-config](https://github.com/shadow-robot/sr-config) folder, don't forget to modify the [launch file](https://github.com/shadow-robot/sr-config/blob/indigo-devel/sr_ethercat_hand_config/launch/sr_rhand.launch) (or [this one](https://github.com/shadow-robot/sr-config/blob/indigo-devel/sr_ethercat_hand_config/launch/sr_lhand.launch) for the left hand). The important thing to remember is to point to the proper ethercat port, robot description, hand serial, pwm control:

```xml
 <arg name="eth_port" value="eth0" />
 <arg name="robot_description" value="$(find sr_description)/robots/shadowhand_extra_lite.urdf.xacro"/>
 <arg name="pwm_control" value="true"/>
 <arg name="hand_serial" value="1066"/>
 ```
