# Best Practices

## Splitting work between different CI servers

Currently build tools support three hosted CI solutions 

  * [Shipppable](https://www.shippable.com)
  * [Semaphore](https://semaphoreci.com)
  * [Circle](https://circleci.com)
 
They also support local run which might be used by any CI setup on the local servers or for manual execution in Docker container.

One of the possible approaches is to split checks between different servers to make builds faster and to reduce the cost for private repositories.
E.g. Circle and Shippable currently propose one worker for private and public repositories.
So it can be used to run fast checkup for all repositories such as roslint code style checks.

Also, the module *build_pr_only* can be used to build only Pull Requests in order to save server time for other repositories.

Semaphore has a scheduled build feature which can be used to run heavy repository checks during the night.

## Open source repositories

Open source repositories can be run free of charge on any of these servers.  

## Local server

If you want to setup Docker based CI server on your local servers you can do the following:

```bash
sudo <build_tools_directory>/bin/sr-run-ci-build.sh master local check_cache,build /catkin_ws/src/build-servers-check/
```
In this example, [build-servers-check](https://github.com/shadow-robot/build-servers-check) is a template repository used to check the status of the build tools.
The following path */catkin_ws/src/build-servers-check/* is the relative location of the repository in the user's HOME directory.
The absolute location is *$HOME/catkin_ws/src/build-servers-check/*
The build tools will copy the source code to the Docker container file system and execute all modules on it.

## Developer's machine

If you could not reproduce locally the issues on the CI server, you can use the ability to run the Docker based builds on your machine following these steps:

First of all install [Docker](https://www.docker.com/)

Next you need to download Shadow Robot images from [Docker Hub](https://hub.docker.com/r/shadowrobot/ubuntu-ros-indigo-build-tools/) using the following command:

```bash
sudo docker pull shadowrobot/ubuntu-ros-indigo-build-tools
```

Now you can start Docker container

```bash
sudo docker run -it -w "/root/sr-build-tools/ansible" --env=HOME=/root --name "ros_ubuntu" -v $HOME:/host:rw "shadowrobot/ubuntu-ros-indigo-build-tools" bash
```

If you've followed the steps above, you should have a Docker container named **ros_ubuntu**. You can now start and attach it:

```bash
sudo docker start ros_ubuntu
sudo docker attach ros_ubuntu
```
**Please note** that bash default folder is */root/sr-build-tools/ansible/*.

Now you are ready to start build tools in the same way as it is done on the server.

```bash
sudo PYTHONUNBUFFERED=1 ansible-playbook -v -i "localhost," -c local docker_site.yml --tags "local,check_cache,code_coverage" -e "local_repo_dir=/host/catkin_ws/src/build-servers-check/ local_test_dir=/root/workspace/test_results local_code_coverage_dir=/root/workspace/coverage_results"
```

This command will execute build, unit_tests and code_coverage modules.
Results of the operation will be written to local_test_dir and local_code_coverage_dir on Docker container.

If you want to work with another repository is better to delete the existing Docker container and create a new one or use another name instead of *ros_ubuntu*:

```bash
sudo docker rm ros_ubuntu
```

## Run code style check locally

Read description of command line utility [here](/bin/README.md)


## How to analyse build log
 
[![How to analyse build log](http://img.youtube.com/vi/dFBWxV8WkHk/0.jpg)](http://www.youtube.com/watch?v=dFBWxV8WkHk)
