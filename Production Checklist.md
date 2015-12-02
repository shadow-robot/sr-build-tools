# New Computer - Production Checklist


| **No**  | **ITEM**  | **Checked**  |
|:-------:|:--------- |:------------ |
| 1 | Ubuntu is installed  |  |
| 2 | Install ROS, Shadow Software and extras  || |


## How to Install Ubuntu
 - [ ] Introduce the USB "Ubuntu Trusty" (64bits, Ubuntu 14.04)
 - [ ] Boot the computer from the USB 2.0
 - [ ] Click Install Ubuntu. Language: English
 - [ ] Preparing to install Ubuntu. Download updates while installing: ON. Install this third-party software: OFF.
 - [ ] Choose the drive and install now
 - [ ] Where are you? Select the delivery destination
 - [ ] Choose U.K. keyboard layout
 - [ ] Your name: Shadow Admin at 'company_name'
  - [ ] Your PC name: shadow-'company_name'
  - [ ] Pick a username: **sysadmin**
  - [ ] Password: hand
  - [ ]  Require my password to log in: ON
 - [ ] Once installed, add the keyboard layout of the country of destination

## Install ROS, Shadow Software and extras

- Run the following command command. You can  replace `indigo-devel` with the name of the branch you want to use (**it must exist on github**). 
```
curl -L bit.ly/prod-install | bash -s indigo-devel
```

- In the [sr-config](https://github.com/shadow-robot/sr-config) folder, don't forget to modify the [sr_rhand.launch file](https://github.com/shadow-robot/sr-config/blob/indigo-devel/sr_ethercat_hand_config/launch/sr_rhand.launch) (or [sr_lhand.launch](https://github.com/shadow-robot/sr-config/blob/indigo-devel/sr_ethercat_hand_config/launch/sr_lhand.launch) for the left hand). The important thing to remember is to point to the proper ethercat port, robot description, mapping file, hand serial, pwm control:
```xml
<launch>
  <include file="$(find sr_robot_launch)/launch/srhand.launch">
    <arg name="eth_port" value="eth2" />
    <arg name="hand_serial" value="1050" />
    <arg name="hand_id" value="rh" />
    <arg name="robot_description" value="$(find sr_description)/robots/shadowhand_motor.urdf.xacro" />
    <arg name="mapping_path" value="$(find sr_edc_launch)/mappings/default_mappings/rh_ethercat.yaml"/>

    <arg name="sim" value="false"/>
  </include>
</launch>
```

## Updating the installation or rerunning a failed install

You can rerun the command any time logged in and from the **sysadmin** user home directory to update the installation.
```
curl -L bit.ly/prod-install | bash -s indigo-devel
```
