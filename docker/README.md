This folder contains Dockerfiles for Ubuntu 14.04 ROS Indigo and Ubuntu 16.04 ROS kinetic images. Also, oneliner script is provided to pull a specified docker image and run the respective container.

It is used to make build process run faster.

# Images

## Build Tools Images

The build tools images are largely used to speed up builds of dependent images by avoid re-compilation/installation of common dependencies.

### Build Tools Base images

#### build-tools:trusty-indigo

Built from `ros:indigo-perception`. Adds a user, amongst other things, to speed up CI builds. Forms the basis for most ROS Indigo images. [Dockerfile](ros/indigo/base/Dockerfile).

#### build-tools:xenial-kinetic

[Dockerfile](ros/kinetic/base/Dockerfile)

Built from `ros:kinetic-perception`. Adds a user, amongst other things, to speed up CI builds. Forms the basis for most ROS Kinetic images.

### Build Tools IDE images

#### build-tools:trusty-indigo-ide

Built from [`build-tools:trusty-indigo`](#build-toolstrusty-indigo). Adds IDEs (pycharm and qtcreator at the time of writing). [Dockerfile](ros/indigo/ide/Dockerfile).

#### build-tools:trusty-indigo-ide-intel

Built from [`build-tools:trusty-indigo-ide`](#build-toolstrusty-indigo-ide). Adds support for Intel GPUs (i.e. CPU-integrated graphics). [Dockerfile](ros/indigo/intel_ide/Dockerfile).

#### build-tools:trusty-indigo-ide-nvidia

Built from [`build-tools:trusty-indigo-ide`](#build-toolstrusty-indigo-ide). Adds support for Nvidia GPUs. [Dockerfile](ros/indigo/nvidia_ide/Dockerfile).

#### build-tools:xenial-kinetic-ide

Built from [`build-tools:xenial-kinetic`](#build-toolsxenial-kinetic). Adds IDEs (pycharm and qtcreator at the time of writing). [Dockerfile](ros/kinetic/ide/Dockerfile).

#### build-tools:xenial-kinetic-ide-intel

Built from [`build-tools:xenial-kinetic-ide`](#build-toolsxenial-kinetic-ide). Adds support for Intel GPUs (i.e. CPU-integrated graphics). [Dockerfile](ros/kinetic/intel_ide/Dockerfile).

#### build-tools:xenial-kinetic-ide-nvidia

[Dockerfile](ros/kinetic/nvidia_ide/Dockerfile)
Built from [`build-tools:xenial-kinetic-ide`](#build-toolsxenial-kinetic-ide). Adds support for Nvidia GPUs.

### Other Build Tools Images

#### build-tools:trusty-indigo-test

Built from `ubuntu:trusty`. Trusty, ROS Indigo test image? Not sure. [Dockerfile](ros/indigo/test/Dockerfile).

#### build-tools:xenial-kinetic-test

Built from `ubuntu:xenial`. Xenial, ROS Kinetic test image? Not sure. [Dockerfile](ros/kinetic/test/Dockerfile).

#### build-tools:xenial-kinetic-mongodb-fix

Built from [`shadowrobot/build-tools:xenial-kinetic`](#build-toolsxenial-kinetic). Builds a legacy mongo driver that enables mongodb to work with Kinetic. The Xenial-era mongo driver does not include a header file that `ros-warehouse-mongo` requires to build. [Dockerfile](ros/kinetic/mongodb-driver/Dockerfile).

#### build-tools:xenial-kinetic-mongodb-openrave

Built from [`shadowrobot/build-tools:xenial-kinetic-mongodb-fix`](#build-toolsxenial-kinetic-mongodb-fix). Adds openrave and its dependencies. Used mainly for grasp generation. [Dockerfile](ros/kinetic/openrave/Dockerfile).

## Shadow Hand Images

These images contain the Shadow Dexterous Hand (Hand E) stack with various additions.

### dexterous-hand:indigo

Built from [`build-tools:trusty-indigo-ide`](#build-toolstrusty-indigo-ide). Adds Indigo Hand E stack. [Dockerfile](shadow-hand/indigo/base/Dockerfile).

### dexterous-hand:indigo-intel-ide

Built from [`dexterous-hand:indigo`](#dexterous-handindigo). Adds support for Intel GPUs (i.e. CPU-integrated graphics). [Dockerfile](shadow-hand/indigo/intel_ide/Dockerfile).

### dexterous-hand:indigo-nvidia-ide

Built from [`dexterous-hand:indigo`](#dexterous-handindigo). Adds support for Nvidia GPUs. [Dockerfile](shadow-hand/indigo/nvidia_ide/Dockerfile).

### dexterous-hand:kinetic

Built from [`build-tools:xenial-kinetic-ide`](#build-toolsxenial-kinetic-ide). Adds Kinetic Hand E stack. [Dockerfile](shadow-hand/kinetic/base/Dockerfile).

### dexterous-hand:kinetic-intel-ide

Built from [`dexterous-hand:kinetic`](#dexterous-handkinetic). Adds support for Intel GPUs (i.e. CPU-integrated graphics). [Dockerfile](shadow-hand/kinetic/intel_ide/Dockerfile)

### dexterous-hand:kinetic-nvidia-ide

Built from [`dexterous-hand:kinetic`](#dexterous-handkinetic). Adds support for Nvidia GPUs. [Dockerfile](shadow-hand/kinetic/nvidia_ide/Dockerfile)

# Oneliner


bash <(curl -Ls https://raw.githubusercontent.com/shadow-robot/sr-build-tools/master/docker/launch.sh) -i [image_name] -n [container_name] -e [interface] -b [git_branch] -r [true/false] -g [true/false]

Posible options for the oneliner are:

* -i or --image             Name of the Docker hub image to pull
* -u or --user              Docker hub user name
* -p or --password          Docker hub password
* -r or --reinstall         Flag to know if the docker container should be fully reinstalled (Default: false)
* -n or --name              Name of the docker container
* -e or --ethercatinterface Ethercat interface of the hand
* -g or --nvidiagraphics    Enable nvidia-docker (Default: false)
* -d or --desktopicon       Generates a desktop icon to launch the hand (Default: true)
* -b or --configbranch      Specify the branch for the specific hand (Only for dexterous hand)


To begin with, the oneliner checks the installation status of docker. If docker is not installed then a new clean installation is performed. If the required image is private, 
then a valid Docker Hub account with pull credentials from Shadow Robot's Docker Hub is required. Then, the specified docker image is pulled and a docker 
container is initialized. For all available images please refer to section above. Finally, a desktop shortcut is generated. This shortcut starts the docker container and launches 
the hand.

Usage example hand E:
```
bash <(curl -Ls https://raw.githubusercontent.com/shadow-robot/sr-build-tools/master/docker/launch.sh) -i shadowrobot/dexterous-hand:kinetic -n hand_e_kinetic_real_hw -e enp0s25 -b shadowrobot_demo_hand -r true -g false
```

Usage example agile-grasper:
```
bash <(curl -Ls https://raw.githubusercontent.com/shadow-robot/sr-build-tools/master/docker/launch.sh) -i shadowrobot/agile-grasper:kinetic-release -n hand_e_kinetic_real_hw -e enp0s25 -r true -g false
```
