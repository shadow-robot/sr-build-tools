# Shippable Server

## How to setup

The following repository can be used as an example of [Shippable](https://wwww.shippable.com/) configuration [build servers check](https://github.com/shadow-robot/build-servers-check)

The process of setting up [Shippable](https://wwww.shippable.com/) server

  * In the root folder of your repository
    * Copy *shippable.yml* from [build servers check](https://github.com/shadow-robot/build-servers-check) repository. 
    * Remove *env* section and *after_failure* sections.
    * Create *repository.rosinstall* in case if you want to install some packages from source code. This file should be in in [rosinstall](http://wiki.ros.org/rosinstall) format.
      You can use *repository.rosinstall* [build servers check](https://github.com/shadow-robot/build-servers-check) as an example.
  * *shippable.yml* contains list of the modules which can be used in the **used_modules** variable. It can be adjusted to any amount of the [modules needed](../modules.md).
  * Login to [Shippable](https://wwww.shippable.com/) using GitHub account
  * Follow simple process to add your repository to projects list
  * Go to "Settings" tab in the top left corner of your project and set following values
    * **Docker Build** - *No*
    * **Pull Image from** - *shadowrobot/ubuntu-ros-indigo-build-tools*
    * **Push Build** - *No*
    * **Cache Container** - *No*
  * To use [CodeCov](https://codecov.io) tool you need to encrypt variable **CODECOV_TOKEN=\<UUID from CodeCov\>** and put it into *env* section of *shippable.yml*
  * You can use section *after_failure* from [build servers check](https://github.com/shadow-robot/build-servers-check) repository as example of Slack notification of the failed builds. 
    Encrypted variable **SLACK_WEB_HOOK_URL** need to be defined and put into *env* section.
   
More information about *shippable.yml* features can be found [here](http://shippable-docs-20.readthedocs.org/en/latest/config.html#configuration). 
