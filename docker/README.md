This folder contains Dockerfiles for Ubuntu 18.04 ROS Melodic, Ubuntu 20.04 ROS Noetic images, Ubuntu 20.04 ROS2 Humble and Ubuntu 20.04 ROS2 Rolling. Also, one-liner is provided to pull a specified docker image and run the respective container.

It is used to make build process run faster.

# Images

## Build Tools Images

The build tools images are largely used to speed up builds of dependent images by avoid re-compilation/installation of common dependencies.

### Build Tools Base images

#### build-tools:kinetic

Built from `ros:kinetic-perception`. Adds a user, amongst other things, to speed up CI builds. Forms the basis for most ROS Kinetic images. [Dockerfile](ros/kinetic/base/Dockerfile).

#### build-tools:kinetic-eigen_3.3.7

Built from `shadowrobot/build-tools:xenial-kinetic`. Adds Eigen v. 3.3.7 to Kinetic ROS image. [Dockerfile](ros/kinetic/eigen_3.3.7/Dockerfile).

#### build-tools:melodic

Built from `ros:melodic-perception`. Adds a user, amongst other things, to speed up CI builds. Forms the basis for most ROS Melodic images. [Dockerfile](ros/melodic/Dockerfile).

#### build-tools:noetic

Built from `ros:noetic-robot`. Adds a user, amongst other things, to speed up CI builds. Forms the basis for most ROS Noetic images. [Dockerfile](ros/noetic/Dockerfile)

#### build-tools:focal-humble
Built from `ros:humble-ros-base`. Adds a user, amongst other things, to speed up CI builds. Forms the basis for most ROS2 Noetic images. [Dockerfile](ros2/humble/Dockerfile)

#### build-tools:focal-rolling
Built from `osrf/ros2:nightly`. Adds a user, amongst other things, to speed up CI builds. Forms the basis for most ROS2 Noetic images (Gets nightly ROS2 build). [Dockerfile](ros2/humble/Dockerfile)
