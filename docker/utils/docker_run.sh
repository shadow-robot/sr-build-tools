#!/bin/bash

# This is a convenience script to run our docker containers in a Nvidia or non-Nvidia environment.
# You can append any number of normal docker flags or arguments. Examples:
# docker_run.sh shadowrobot/dexterous-hand:kinetic-v1.0.33
# docker_run.sh --name my_new_container shadowrobot/dexterous-hand:kinetic-v1.0.33
# docker_run.sh --name my_new_container shadowrobot/dexterous-hand:kinetic-v1.0.33 bash

# Docker run command, arguments, environment variables and volumes common to Nvidia and non-Nvidia
run_command="docker run -it --security-opt seccomp=unconfined --network=host --pid=host --privileged"
environment_variables=("DISPLAY" "QT_X11_NO_MITSHM=1" "LOCAL_USER_ID=$(id -u)")
volumes=("/tmp/.X11-unix:/tmp/.X11-unix:rw" "/dev/input:/dev/input:rw" "/run/udev/data:/run/udev/data:rw")

# Detect if Nvidia GPU is available (installed and in-use)
command -v nvidia-smi >/dev/null 2>&1
if [ $? -eq 0 ]; then
    nvidia=true
    # Get Nvidia major version number
    nvidia_smi="$(nvidia-smi)"
    nvidia_version=$(echo ${nvidia_smi} | sed 's/.*Driver Version: \([^ \.]*\).*/\1/')
    echo "Nvidia GPU detected, using Nvidia driver version ${nvidia_version} for new container."
    # Add nvidia-specific docker arguments, environment variables and volumes
    run_command="${run_command} --runtime nvidia"
    environment_variables+=("PATH=/usr/lib/nvidia-${nvidia_version}/bin:${PATH}" "LD_LIBRARY_PATH=/usr/lib/nvidia-${nvidia_version}" "NVIDIA_DRIVER_CAPABILITIES=all" "NVIDIA_VISIBLE_DEVICES=all")
    volumes+=("/usr/lib/nvidia-${nvidia_version}:/usr/lib/nvidia-${nvidia_version}:rw")
else
    echo "No Nvidia GPU detected, using intel graphics for new container."
    nvidia=false
fi

# Add all environment variables to the final run command
for e in ${environment_variables[@]}; do
  run_command="${run_command} -e $e"
done
# Add all volumes to the final run command
for v in ${volumes[@]}; do
  run_command="${run_command} -v $v"
done
# Add all additional (pass-though) arguments to the final run command
run_command="${run_command} $@"

newline=$'\n'
echo "Running docker command:${newline}${run_command}"
${run_command}
