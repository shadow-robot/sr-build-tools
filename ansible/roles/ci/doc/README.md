# Continuous Integration server support

The main purpose of the CI server support is the ability to use available hosted CI\CD server solutions for current and future projects in an agile fashion.
In order to achieve this goal, extra roles were developed for Ansible build tools.

For more details please read following information:

  * [How does it work](#how-does-it-work) - tools' design
  * [Main modules](#build-tools-modules) - Ansible roles for CI servers run.
  * [Best practices](#best-practices) - recommended way of using tools
  * [Exclude licence file](exclude_style_check.md)
  * supported servers 
    * [Travis](setup/travis.md)
    * [Shippable](setup/shippable.md)
    * [Circle](setup/circle.md)
    * [Semaphore](setup/semaphore.md)
    * [Local Jenkins](setup/jenkins.md)

# How does it work

The build tools were created to run on the [Docker](https://www.docker.com/) based CI servers.
The Docker image for all builds are hosted on [AWS ECR](https://eu-west-2.console.aws.amazon.com/ecr/repositories/public/080653068785/build-tools?region=eu-west-2)

The build script is loading Ubuntu 20.04 Docker image with pre-installed ROS Noetic.
This image is dependent on Ubuntu and ROS repositories in the Docker Hub, which means that the image is rebuild as soon as any of parent images change.

The build tools also put a special marker in the image, which indicates that ROS was installed using their script and the workspace was created as well.
The supported CI servers download the latest version of the Docker image and run Ansible build tools inside.
The developers can choose which modules to use.

# Build Tools Modules
## List of modules

  * **build_pr_only** - skip build after commit if it is not PR
  * **build** - build project using catkin_make.
  * **software_tests** - run unit ([gtest, unittest](http://wiki.ros.org/rosunit)) and integration 
  ([rostest](http://wiki.ros.org/rostest)) tests and place results in special folder if defined by CI server 
  (e.g. artifacts for Circle CI)
  * **all_tests** - run **software_tests** tests described above as well as hardware tests
  * **benchmarking** - run benchmarking of the functionality based on rostest
  * **check_build** - long running module. Compile independently each package in the project cleaning devel and build 
  folder beforehand and check if all dependencies are declared in CMakeList.txt correctly.
  * **code_style_check** - run [roslint](http://wiki.ros.org/roslint) to check C++ and Python code, also runs [pylint](https://pypi.org/project/pylint/) for python files, [xmllint](http://xmlsoft.org/xmllint.html) to check all XML files (beginning with <) in all packages of the project and
  [catkin_lint](http://fkie.github.io/catkin_lint) to check all packages using catkin_lint.
  * **check_license** - check if copyright notice is present in all the files and the LICENSE file exsists in the 
  repository. 
  * **check_install** - quick check of the catkin_make_isolated install comparably to full Debian files build
  * **build_debs** - generate Debian package files using bloom
  * **check_deb_make** - try to install the deb packages generated with **build_debs**. Check if installation is 
  working correctly. It assumes that packages installed from source code would be available to rosdep during package 
  deployment.
  * **complete_deb_check** - the same as **check_deb_make** but it require all packages to be accessible to rosdep 
  during module execution.
  * **upload_debs** - generate using **build_debs**, checks using **check_deb_make** and upload the deb files to an 
  aptly server.
  * **python_code_coverage** - generate code coverage for Python code
  * **cpp_code_coverage** - generate code coverage for C++ code
  * **code_coverage** - generate code coverage for Python and C++ code
  * **codecov_tool** - post Python and C++ code coverage results to [CodeCov](https://codecov.io)

# Best Practices

## Splitting work between different CI servers

Currently build tools support following hosted CI solutions 

  * [Travis](setup/travis.md)
  * [Shipppable](https://www.shippable.com)
  * [Semaphore](https://semaphoreci.com)
  * [Circle](https://circleci.com)
 
They also support local run which might be used by any CI setup on the local servers or for manual execution in Docker container.

One of the possible approaches is to split checks between different servers to make builds faster and to reduce the cost for private repositories.
E.g. Circle and Shippable currently propose one worker for private and public repositories.
So it can be used to run fast checkup for all repositories such as roslint code style checks.

Also, the module *build_pr_only* can be used to build only Pull Requests in order to save server time for other repositories.

Semaphore has a scheduled build feature which can be used to run heavy repository checks during the night.

Travis has setting to run build only for Pull Requests.

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

Next you need to download Shadow Robot images from [ECR](https://eu-west-2.console.aws.amazon.com/ecr/repositories/public/080653068785/build-tools?region=eu-west-2) using the following command:

```bash
sudo docker pull public.ecr.aws/shadowrobot/build-tools:focal-noetic
```

Now you can start Docker container named **ros_ubuntu**

```bash
sudo docker run -it -w "/root/sr-build-tools/ansible" --env=HOME=/root --name "ros_ubuntu" -v $HOME:/host:rw "public.ecr.aws/shadowrobot/build-tools:focal-noetic" bash
```

If you want to use this container in the future you can use following commands to start and attach to it:

```bash
sudo docker start ros_ubuntu
sudo docker attach ros_ubuntu
```
**Please note** that bash default folder is */root/sr-build-tools/ansible/*.

In order to start build tools you need to run Ansible playbook:

```bash
sudo PYTHONUNBUFFERED=1 ansible-playbook -v -i "localhost," -c local docker_site.yml --tags "local,check_cache,code_coverage" -e "local_repo_dir=/host/catkin_ws/src/build-servers-check/ local_test_dir=/root/workspace/test_results local_code_coverage_dir=/root/workspace/coverage_results"
```

This command will execute build, unit_tests and code_coverage modules.
Results of the operation will be written to local_test_dir and local_code_coverage_dir on Docker container.

If you want to work with another repository is better to delete the existing Docker container and create a new one or use another name instead of *ros_ubuntu*:

```bash
sudo docker rm ros_ubuntu
```

The video tutorial about troubleshooting:

[![How to troubleshoot build issue locally](http://img.youtube.com/vi/Ls5THum5ZGc/0.jpg)](http://www.youtube.com/watch?v=Ls5THum5ZGc)

## Run code style check locally

Read description of command line utility [here](/bin/README.md)


## How to analyse build log
 
[![How to analyse build log](http://img.youtube.com/vi/dFBWxV8WkHk/0.jpg)](http://www.youtube.com/watch?v=dFBWxV8WkHk)

## Running hardware tests

On the software side you need to enclose appropriate rostests into IF statement in CMakeList.txt file as following
```cmake
if (RUN_HARDWARE_TESTS)
  find_package(rostest REQUIRED)
  add_rostest(test/test_simple_hardware.test)
endif()
```
Also you need to specify module **all_tests** from the [modules list](modules.md) in build configuration. 

In order to run hardware tests you might need separate machine and access to serial or ethernet ports on it.
There is possibility to provide access to host machine hardware in **--privileged** mode.
The build tools read environment variable **docker_flags** and add any parameters from there to docker container.
So in this case you need to execute main script using following command
```bash
sudo docker_flags="--privileged" <build_tools_directory>/bin/sr-run-ci-build.sh master local check_cache,build /catkin_ws/src/build-servers-check/
```
**Please note** that these flags are propagated to docker container if server type is local

## Using another Docker Hub image

By default build tools are using *public.ecr.aws/shadowrobot/build-tools:focal-noetic* [ECR](https://eu-west-2.console.aws.amazon.com/ecr/repositories/public/080653068785/build-tools?region=eu-west-2) image.
You can inherit your image from it.
The Dockerfile for *public.ecr.aws/shadowrobot/build-tools* can be found [here](https://github.com/shadow-robot/sr-build-tools/blob/master/docker/ci/Dockerfile) and it can be used as reference.

In order to provide the new name of the image set environment variable **docker_image**.
 For example
```bash
sudo docker_image="shadowrobot/hand-project-ubuntu-image" <build_tools_directory>/bin/sr-run-ci-build.sh master local check_cache,build /catkin_ws/src/build-servers-check/
```

## Private repository dependencies

Some private repositories might depend on other private repositories source code.
In this case you may refer them in *repository.rosinstall* file in the following format
```yaml
- git:
    local-name: my_private_repo
    uri: https://{{github_login}}:{{github_password}}@github.com/my-company/my_private_repo
    version: noetic-devel
```
The values of the **github_login** and **github_password** variables would be replaced by the environment variables **GITHUB_LOGIN** and **GITHUB_PASSWORD** values.
The majority of the hosted servers has ability to store encrypted environment variables.
**GITHUB_LOGIN** and **GITHUB_PASSWORD** should store credentials which has access to needed private repository.
