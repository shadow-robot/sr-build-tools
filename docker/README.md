This folder contains Dockerfiles for Ubuntu 14.04 ROS Indigo and Ubuntu 16.04 ROS kinetic images.

It is used to make buid process run faster.

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
