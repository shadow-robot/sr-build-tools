FROM shadowrobot/dexterous-hand:kinetic

MAINTAINER "Shadow Robot's Software Team <software@shadowrobot.com>"

LABEL Description="Image for using sr_recognizer package" Version="1.0"

ENV v4r_and_openni_kinetic="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/$toolset_branch/docker/utils/v4r_and_openni_kinetic.sh"
ENV V4R_DIR="/home/user/v4r/build"

RUN set -e && \

    curl -s "$v4r_and_openni_kinetic" | bash && \
   
    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /home/$MY_USERNAME/.ansible /home/$MY_USERNAME/.gitconfig

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/bin/terminator"]
