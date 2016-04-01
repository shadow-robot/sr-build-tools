#How to test a sr-build-tools branch#

##Docker##
Install docker [Docker install page](https://docs.docker.com/linux/step_one/).
Download Shadow robot docker image from Docker Hub.
```bash
sudo docker pull shadowrobot/ubuntu-ros-indigo-build-tools
```

Start Docker container named ros_ubuntu

```bash
sudo docker run -it -w "/root/sr-build-tools/ansible" --env=HOME=/root --name "ros_ubuntu" -v $HOME:/host:rw "shadowrobot/ubuntu-ros-indigo-build-tools" bash
```
If you exit the Docker container, it remains on the machine unless removed specifically.
To start it again use
```
sudo docker start ros_ubuntu
sudo docker attach ros_ubuntu
```
If you want to have two Docker containers you can use the same command but give it a different name.
If you do not specify a name, Docker automatically generate a name for it.

Here are some useful docker commands:
docker pull <image name> : pulls the docker image
docker run <image name> : run the image
docker run <image name> -it : run the docker image in interactive mode
sudo docker ps -a : lists the running docker images
sudo docker start <name of your container> : starts a docker image
sudo docker attach <name of your container> : actually gets into the docker image
sudo docker rm < name of your container> : deletes the container

##Tasks on Docker image##
Docker container does not have ubuntu desktop. This can cause problem for running production script.
Install the *ubuntu-desktop* with following command.
```bash
sudo apt-get install --no-install-recommends ubuntu-desktop
```

If you want to test the master branch you can use the one line script in the docker session.
Although both devel and production scripts are checked every night in Jenkins.
```bash
curl -L bit.ly/prod-install | bash -s indigo-devel
```

```bash
curl -L bit.ly/dev-machine 
```

If you want to run a branch of sr-build-tools for development script use the following command
```bash
curl -L bit.ly/dev-machine -b <branch name> 
```

For production script use
```bash
curl -L bit.ly/prod-install | bash -s indigo-devel <branch name>
```

**NOTE** If the main script is modified (**bin/setup_production_machine** for production script and  **bin/setup_dev_machine** for development script) the bit.ly links would not work as they point to master script.
 To overcome this simply replace them with the rawgithubcontent link.
e.g. 
```bash
curl -L raw.githubusercontent.com/shadow-robot/sr-build-tools/F%23249_add_blockly/bin/setup_dev_machine | bash -s indigo-devel F#49_add_blockly
```
will run the production script from branch *F#49_add_blockly* .

After running the production script make sure to switch user to **hand**. 

If you want to check Docker graphical interface, you need to install X11 and openssh on your machine (docker image has it already).
Make sure you initialize the openssh on Docker.
```bash
sudo /etc/init.d/ssh start
```
Find the ip of Docker image with *ifconfig*.
SSH to Docker image with 
```bash
ssh -X hand@ip
```

Make sure to override the localization in the ssh window with 
```bash
export LC_ALL="C"
```

