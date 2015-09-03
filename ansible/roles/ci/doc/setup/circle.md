# Circle CI Server

## How to setup

The following repository can be used as an example of [Circle CI](https://circleci.com/) configuration [build servers check](https://github.com/shadow-robot/build-servers-check)

The process of setting up [Circle CI](https://circleci.com/) server

1. In the root folder of your repository
    * Copy *circle.yml* from [build servers check](https://github.com/shadow-robot/build-servers-check) repository. 
    * Create *repository.rosinstall* in case if you want to install some packages from source code. This file should be in in [rosinstall](http://wiki.ros.org/rosinstall) format.
      You can use *repository.rosinstall* [build servers check](https://github.com/shadow-robot/build-servers-check) as an example.
2. *circle.yml* contains list of the modules which can be used in the **used_modules** variable. It can be adjusted to any amount of the [modules needed](../modules.md).
3. Login to [Circle CI](https://circleci.com/) using GitHub account
4. Follow simple process to add your repository to projects list
5. To use [CodeCov](https://codecov.io) tool you need to put variable **CODECOV_TOKEN** in *Environment variables* section of the project settings

More information about *circle.yml* features can be found [here](https://circleci.com/docs/configuration). 

