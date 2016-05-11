FROM shadowrobot/ros-tensorflow:latest

# Installing simplecv
RUN apt-get update && \
    apt-get install -y ipython python-opencv python-scipy python-numpy python-pygame python-setuptools python-pip && \
    pip install svgwrite && \
    pip install https://github.com/sightmachine/SimpleCV/zipball/develop

RUN mkdir /{code,data,results}

# Building image retraining from tensorflow
RUN cd /tensorflow && \
    bazel build tensorflow/examples/image_retraining:retrain

ENTRYPOINT bash
