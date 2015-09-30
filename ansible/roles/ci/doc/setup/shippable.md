# Shippable Server

## How to setup

The following repository can be used as an example of a [Shippable](https://wwww.shippable.com/) configuration: [build servers check](https://github.com/shadow-robot/build-servers-check)

The process of setting up [Shippable](https://wwww.shippable.com/) server:

  * In the root folder of your repository:
    * Copy *shippable.yml* from [build servers check](https://github.com/shadow-robot/build-servers-check) repository. 
    * Remove *env* section and *after_failure* sections.
    * Create *repository.rosinstall* in case you want to install some packages from source code. This file should be in [rosinstall](http://wiki.ros.org/rosinstall) format.
      You can use *repository.rosinstall* [build servers check](https://github.com/shadow-robot/build-servers-check) as an example.
  * *shippable.yml* contains a list of the modules which can be used in the **used_modules** variable. It can be adjusted to any amount of [modules needed](../modules.md).
  * Login to [Shippable](https://wwww.shippable.com/) using GitHub account
  * Follow the simple process to add your repository to the projects list
  * Go to "Settings" tab in the top left corner of your project and set following values
    * **Docker Build** - *No*
    * **Pull Image from** - *shadowrobot/ubuntu-ros-indigo-build-tools*
    * **Push Build** - *No*
    * **Cache Container** - *No*
  * In order to post your code coverage results to [CodeCov](https://codecov.io) you need to encrypt variable **CODECOV_TOKEN** and put it into the *env* section of *shippable.yml*
  * You can use section *after_failure* from [build servers check](https://github.com/shadow-robot/build-servers-check) repository as an example of setting Slack notifications of the failed builds. 
    The encrypted variable **SLACK_WEB_HOOK_URL** needs to be defined and put it into the *env* section.
   
More information about *shippable.yml* features can be found [here](http://shippable-docs-20.readthedocs.org/en/latest/config.html#configuration).
 
## Video Tutorial
 
[![Shippable CI build tools setup](http://img.youtube.com/vi/zMw_gpO72mI/0.jpg)](http://www.youtube.com/watch?v=zMw_gpO72mI)
