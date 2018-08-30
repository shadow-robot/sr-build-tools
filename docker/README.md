This folder contains Dockerfiles for Ubuntu 14.04 ROS Indigo and Ubuntu 16.04 ROS kinetic images. Also, one-liner is provided to pull a specified docker image and run the respective container.

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

# One-liner

This one-liner is able to install Docker, download the specified image and create a new container for you. It will also create a desktop icon to start the container and launch the hand.

Before setting up the docker container, the EtherCAT interface ID for the hand needs to be discovered. In order to do so, after plugging the hand’s ethernet cable into your machine and powering it up, please run
```shell
sudo dmesg
```
command in the console. At the bottom, there will be information similar to the one below:
```shell
[490.757853] IPv6: ADDRCONF(NETDEV_CHANGE): enp0s25: link becomes ready
```
In the above example, ‘enp0s25’ is the interface id that is needed. 

With this information you can run the one-liner using the following command
```shell
bash <(curl -Ls bit.ly/launch-sh) -i [image_name] -n [container_name] -e [interface] -b [git_branch] -r [true/false] -g [true/false] -b [sr_config_branch for dexterous hand]
```

Posible options for the oneliner are:

* -i or --image             Name of the Docker hub image to pull
* -u or --user              Docker hub user name
* -p or --password          Docker hub password
* -r or --reinstall         Flag to know if the docker container should be fully reinstalled (default: false)
* -n or --name              Name of the docker container
* -e or --ethercatinterface Ethercat interface of the hand
* -g or --nvidiagraphics    Enable nvidia-docker (default: false)
* -d or --desktopicon       Generates a desktop icon to launch the hand (default: true)
* -b or --configbranch      Specify the branch for the specific hand (Only for dexterous hand)
* -sn or --shortcutname     Specify the name for the desktop icon (default: Shadow_Hand_Launcher)
* -o or --optoforce         Specify if optoforce sensors are going to be used (default: false)
* -l or --launchhand        Specify if hand driver should start when double clicking desktop icon (default: true)
* -bt or --buildtoolsbranch Specify the Git branch for sr-build-tools (default: master)

To begin with, the one-liner checks the installation status of docker. If docker is not installed then a new clean installation is performed. If the required image is private, 
then a valid Docker Hub account with pull credentials from Shadow Robot's Docker Hub is required. Then, the specified docker image is pulled and a docker 
container is initialized. For all available images please refer to section above. Finally, a desktop shortcut is generated. This shortcut starts the docker container and launches 
the hand.

Usage example hand E:
```
bash <(curl -Ls bit.ly/launch-sh) -i shadowrobot/dexterous-hand:kinetic-release -n hand_e_kinetic_real_hw -e enp0s25 -b shadowrobot_demo_hand -r true -g false
```

Usage example hand E for production:
```
bash <(curl -Ls bit.ly/launch-sh) -i shadowrobot/dexterous-hand:kinetic-release -n hand_e_kinetic_real_hw -e enp0s25 -b shadowrobot_demo_hand -r true -g false -l false
```

Usage example modular-grasper:
```
bash <(curl -Ls bit.ly/launch-sh) -i shadowrobot/flexible-hand:kinetic-release -n modular_grasper -e enp0s25 -r true -g false
```

# Using Docker for Production

The process for using Docker to enable production tasks should be fairly simple. The one-liner can be used to configure one ore more container on a computer for carrying out whatever tasks are required. To demonstrate the process of doing this, here is an example with the different parts of the command explained as the command is built up.

## Starting a new container

It's important to make sure that you're always working with the latest version of which ever software you're using. To ensure this, for each new task or hand, you should start a new container, using the ```-r true``` flag ensures that the container will be running the latest version. This container should be used until the task is complete. Unused/abandoned containers will eat up disk space quickly, so make sure to clean up when you're done.

To start the command, enter the oneliner command, with ```-r true``` to pull the latest image.

```bash
bash <(curl -Ls bit.ly/launch-sh) -r true
```

### Which image should I use: ```-i```

As shown [above](#images) there are many different Docker images available for different tasks. In general, there are only a few that will be relevant for production use. The image that will be used is set using the ``` -i ``` flag when running the oneliner, as explained in the [previous section](#one-liner).

#### Hand E

The *shadowrobot/dexterous-hand* images contain the Hand E software. Unless there is a specific reason to use something else, the correct images to use are simply:
* *shadowrobot/dexterous-hand:indigo-release*
* *shadowrobot/dexterous-hand:kinetic-release*

#### Hand H (Modular Grasper)

The *shadowrobot/flexible-hand* images contain the Hand H software. Hand H is only supported on ```kinetic```. In general, the correct image to use is the latest release version:
* *shadowrobot/flexible-hand:kinetic-release*

For this example, we'll start a *dexterous-hand:kinetic-release* docker:

```bash
bash <(curl -Ls bit.ly/launch-sh) -r true -i shadowrobot/dexterous-hand:kinetic-release
```

##### Docker Hub user credentials: ```-u``` and ```-p```

The Hand H software and Docker Images are private. This means that you'll need to provide the one-liner with credentials for Docker Hub to allow the correct access. If you need credentials/have difficulty connecting, contact the [software team](mailto:software@shadowrobot.com)

As the example we're constructing is for Hand E, these options are not required as the image is public.

### Naming your image: ```-n``` and ```-sn```

The name that you give your container should be descriptive of the task for which you wish to it. This will make it easier to keep your containers organised and also to select the correct one if you have multiple on a machine. The container name, specified by the ```-n``` flag should be unique, as **it will be overwritten if you run the one-liner with the same value again**.

The ```-sn``` flag gives the name of the desktop link that will be created for starting the driver. Keeping the container name and shortcut name the same will reduce the chance of confusion.

For example. let's say you want a docker to test a kinetic Hand E, you could use the name "hand_e_kinetic":

```bash
bash <(curl -Ls bit.ly/launch-sh) -r true -i shadowrobot/dexterous-hand:kinetic-release -n hand_e_kinetic -sn hand_e_kinetic
```

### Setting port and config branch: ```-e``` and ```-b```
#### Ethernet port
To select the correct ethernet port when starting a docker, use the one-liner option  ```-e ETH_PORT``` where *ETH_PORT* is the name of the port to which the robot is connected. If you don't know which port to type```dmesg``` into a terminal after you connect the hand to your computer. Near the end of the output, there will be a line like this:

```bash
[490.757853] IPv6: ADDRCONF(NETDEV_CHANGE): enp30s0: link becomes ready
```

In this case, ```enp3s0``` is the correct port, so the one-liner command becomes:

```bash
bash <(curl -Ls bit.ly/launch-sh) -r true -i shadowrobot/dexterous-hand:kinetic-release -n hand_e_kinetic -sn hand_e_kinetic -e enp3s0
```

#### Config branch
For Hand E, the correct config branch for the hand being tested must be specified when the Docker is first started. To do this, use ```-b CONFIG_BRANCH```. For instance to use the Demo hand, you would start the docker with ```-b demohand_E_v1```.


```bash
bash <(curl -Ls bit.ly/launch-sh) -r true -i shadowrobot/dexterous-hand:kinetic-release -n hand_e_kinetic -sn hand_e_kinetic -e enp3s0 -b demohand_E_v1
```

Hand H dockers do not need a specific config branch.

### Starting the driver ```-l```

When starting a new Docker, by default it's configured to run the driver automatically on startup. This is fine if you have simple tests to run or are configuring a customer machine for delivery. However, for other tasks, it can be very useful to just get a ```terminator``` on startup, from where you can start the driver/other programs (e.g. calibration/test etc.) by hand.  Adding ```-l false``` to the oneliner command will do this.

Presuming we do not want the driver to auto-launch for our example, the final command would be:

```bash
bash <(curl -Ls bit.ly/launch-sh) -r true -i shadowrobot/dexterous-hand:kinetic-release -n hand_e_kinetic -sn hand_e_kinetic -e enp3s0 -b demohand_E_v1 -l false
```

### Build tools branch ```-bt```

For testing any changes to sr-build-tools, it is useful to be able to specify the Git branch for sr-build-tools.
By default, build tools branch is master. For example, adding ```-bt F#SRC-1815-Toivo-Launch-File``` to the oneliner command and changing the URL after curl -Ls to the raw version of the launch.sh file in the desired Git branch will make the oneliner use code from F#SRC-1815-Toivo-Launch-File branch of sr-build-tools.

Presuming we do not want the driver to auto-launch for our example, the final command would be:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/shadow-robot/sr-build-tools/F%23SRC-1815-Toivo-Launch-File/docker/launch.sh) -i shadowrobot/flexible-hand:kinetic-v0.2.28 -n flexible_hand_real_hw -e enp0s25 -r true -g false -bt F#SRC-1815-Toivo-Launch-File -l false
```
