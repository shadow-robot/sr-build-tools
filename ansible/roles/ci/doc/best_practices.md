# Best Practices

## Splitting work between different CI servers

Currently build tools support three hosted CI solutions 

  * [Shipppable](https://www.shippable.com)
  * [Semaphore](https://semaphoreci.com)
  * [Circle](https://circleci.com)
 
Also it supports local run which might be used by any CI setup on the local servers or for manual execution in Docker container.

The one of the possible approaches is to split checks between different servers to make builds faster and to reduce cost for private repositories.
E.g. Circle and Shippable currently propose one worker for private and public repositories.
So it can be used to run fast checkup for all repositories such as roslint code style checks.

Also module build_pr_only can be used to build only Pull Requests in order to save server time for other repositories.

Semaphore has scheduled build feature which can be used to run heavy repository checks durng the night.

## Open source repositories

Open source repositories can be run free of charge on any of these server  

## Local server

In case if you want to setup Docker based CI server on your local servers you can use as following

```bash
sudo <build_tools_directory>/bin/sr-run-ci-build.sh master local check_cache,build /catkin_ws/src/build-servers-check/
```
In this example [build-servers-check](https://github.com/shadow-robot/build-servers-check) is template repository used to check status of the build tools.
The following path */catkin_ws/src/build-servers-check/* is relative location of the repository in user's HOME directory.
The absolute location is *$HOME/catkin_ws/src/build-servers-check/*
The build tools will copy source code to Docker container file system and execute all modules on it.

## Developer's machine

If you could not reproduce issues on the CI server locally you can use ability to run Docker based builds on your machine.

First of all install [Docker](https://www.docker.com/)

Next you need to download Shadow Robot images from [Docker Hub](https://hub.docker.com/r/shadowrobot/ubuntu-ros-indigo-build-tools/) using command

```bash
sudo docker pull shadowrobot/ubuntu-ros-indigo-build-tools
```

Now you can start Docker container

```bash
sudo docker run -it -w "/root/sr-build-tools/ansible" --name "ros_ubuntu" -v $HOME:/host:rw "shadowrobot/ubuntu-ros-indigo-build-tools" bash
```

If have already run steps above at least once then you already have Docker container name **ros_ubuntu** and you can just start and attach to it

```bash
sudo docker start ros_ubuntu
sudo docker attach ros_ubuntu
```

To set correct HOME folder run command inside container

```bash
export HOME=/root
```

Go to build-tools folder on container

```bash
cd /root/sr-build-tools/ansible/
```

You are ready to start build tools in the same way as it is done on the server

```bash
sudo PYTHONUNBUFFERED=1 ansible-playbook -v -i "localhost," -c local docker_site.yml --tags "local,check_cache,code_coverage" -e "local_repo_dir=/host/catkin_ws/src/build-servers-check/ local_test_dir=/root/workspace/test_results local_code_coverage_dir=/root/workspace/coverage_results"
```

This command will execute build, unit_tests and code_coverage modules.
Results of the operation will be written to local_test_dir and local_code_coverage_dir on Docker container.

If you want to work with another repository is better to delete existing Docker container and create new one

```bash
sudo docker rm ros_ubuntu
```

## Run code style check locally

Read description of command line utility [here](/bin/README.md)

