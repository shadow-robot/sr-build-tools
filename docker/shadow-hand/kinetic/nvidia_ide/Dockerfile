FROM shadowrobot/dexterous-hand:kinetic

LABEL Description="This ROS Kinetic image contains Shadow's dexterous hand software with build tools. It includes IDE environments. Nvidia compatible" Vendor="Shadow Robot" Version="1.0"

# nvidia-docker hooks
LABEL com.nvidia.volumes.needed="nvidia_driver"

ENV PATH /usr/local/nvidia/bin:${PATH}

ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}
