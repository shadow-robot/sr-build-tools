#!/bin/bash

docker run -it -e DISPLAY -e LOCAL_USER_ID=$(id -u) -p 8000:8000 -p 9000:9000 -v /tmp/.X11-unix:/tmp/.X11-unix:rw --privileged -v /dev/bus/usb:/dev/bus/usb shadowrobot/dexterous-hand:recognizer
