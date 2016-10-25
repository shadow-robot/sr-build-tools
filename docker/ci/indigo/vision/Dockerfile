FROM shadowrobot/ubuntu-ros-indigo-build-tools:latest

MAINTAINER "Shadow Robot's Software Team <software@shadowrobot.com>"

LABEL Description="This image is used to make ROS Indigo based vision projects build faster using build tools" Vendor="Shadow Robot" Version="1.0"

# Installing SimpleCV
RUN apt-get update
RUN apt-get install -y ipython python-opencv python-scipy python-numpy python-pygame python-setuptools python-pip
RUN pip install svgwrite
RUN pip install https://github.com/sightmachine/SimpleCV/zipball/develop

# Installing TensorFlow
RUN sudo pip install --upgrade https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-0.8.0-cp27-none-linux_x86_64.whl

# Installing CUDA toolkit
RUN curl --remote-name http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/cuda-repo-ubuntu1404_7.5-18_amd64.deb
RUN dpkg -i cuda-repo-ubuntu1404_7.5-18_amd64.deb
RUN apt-get update
RUN apt-get install cuda

ENTRYPOINT bash
