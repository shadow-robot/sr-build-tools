FROM ros:indigo

# using bash instead of sh to be able to source
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install -y curl && \
    curl -L bit.ly/dev-machine | bash -s -- -w /workspace/shadow_robot/base

# Cleaning up, deleting all sources
RUN cd /workspace/shadow_robot/base_deps && \
    source /opt/ros/indigo/setup.bash && \
    rospack profile && \
    catkin_make -DCMAKE_INSTALL_PREFIX=/installed_workspace install && \
    source /installed_workspace/setup.bash && \
    rospack profile && \
    cd ../base && \
    rm -rf {build,devel} && \
    catkin_make -DCMAKE_INSTALL_PREFIX=/installed_workspace && \
    catkin_make -DCMAKE_INSTALL_PREFIX=/installed_workspace install && \
    rm -rf  /workspace/shadow_robot

# setup entrypoint
COPY ./entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
