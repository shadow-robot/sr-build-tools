# Shippable Server

## How to setup

The following repository can be used as an example of shippable configuration [Build server check](https://github.com/shadow-robot/build-servers-check)

Process of setting up shippable server is following

1. In the root folder of your repository
    * Copy *shippable.yml* from build server check repository. Remove env section and after-install sections.
2. Create *repository.rosinstall* in case if you want to install some packages from source code. This file should be in in [rosinstall](http://wiki.ros.org/rosinstall) format.
   You can use *repository.rosinstall* [Build server check](https://github.com/shadow-robot/build-servers-check) as an example.
3. *shippable.yml* contains list of the modules which can be used in the **used_modules** variable. It can be adjusted to any amount of the [modules needed](../modules.md).
4. Login to [Shippable](https://wwww.shippable.com/) using GitHub account
5. Follow simple process to add your repository to projects list
6. Go to "Settings" tab in the top left corner of your project and set following values
    * **Docker Build** - *No*
    * **Pull Image from** - *shadowrobot/ubuntu-ros-indigo-build-tools*
    * **Push Build** - *No*
    * **Cache Container** - *No*
7. To use [CodeCov](https://codecov.io) tool you need to encrypt variable **CODECOV_TOKEN=<UUID from CodeCov>** and put it into env section of *shippable.yml*
