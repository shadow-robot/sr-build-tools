#How to test a sr-build-tools branch#

##Docker##
Start by installing docker. Check [Docker install page](https://docs.docker.com/linux/step_one/).
You may also find useful information on [Source install page](http://shadow-robot.readthedocs.org/en/latest/generated/shadow_robot/INSTALL.html) useful.

Download plain ubuntu docker image from Docker Hub.
```bash
sudo docker pull ubuntu:14.04.4
```

Start Docker container named ubuntu_trusty

```bash
sudo docker run -it -w "/root/sr-build-tools/ansible" --env=HOME=/root --name "ubuntu_trusty" -v $HOME:/host:rw "ubuntu:14.04.4" /bin/bash
```
If you exit the Docker container, it remains on the machine unless removed specifically.
To start it again use
```
sudo docker start ubuntu_trusty
sudo docker attach ubuntu_trusty
```
If you want to have two Docker containers you can use the same command but give it a different name.
If you do not specify a name, Docker automatically generate a name for it.

Here are some useful docker commands:

**docker pull <image name>**: pulls the docker image

**docker run <image name>** : run the image

**docker run <image name> -it** : run the docker image in interactive mode

**sudo docker ps -a**: lists the running docker images

**sudo docker start <name of your container>**: starts a docker image

**sudo docker attach <name of your container>**: actually gets into the docker image

**sudo docker rm < name of your container>**: deletes the container

##Tasks on Docker image##
Docker container does not have ubuntu desktop. This can cause problem for running production script.
Install the *ubuntu-desktop* with following command.
```bash
sudo apt-get install --no-install-recommends ubuntu-desktop
```

**Note** dev-machine script can be installed from any user as long as it has *sudo* privilege.
Production script creates a **hand** user and fails if it is run from **hand** user.

##Testing master branches##
If you want to test the master branch you can use the one line script in the docker session.
Although both devel and production scripts are checked every night in Jenkins.
```bash
curl -L bit.ly/prod-install | bash -s indigo-devel
```

```bash
curl -L bit.ly/dev-machine | bash -s -- -w ~{{ros_user}}/projects/shadow_robot/base
```
If you want to create workspaces in a different location, specify it after -w {{ros_user}}.
If no parameter is specified, they will be created *catkin_ws* and *catkin_ws_deps*.

##Testing other branches##

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

**N.B.** There are minor differences between the production script and development script. The development script uses -b for sr-build-tools and -c for sr_config branch name.
The production script uses first argument (after bash -s) for sr_config branch and second argument for sr-build-tools branch.

##Testing full UI
To test the UI, use [VirtualBox](http://www.virtualbox.org/).
```bash
sudo apt-get install virtualbox
```
If don't already have it create a new ubuntu machine and install ubuntu on it.

It is better to clone the machine and use the cloned one (to save ubuntu installation time for next efforts).
