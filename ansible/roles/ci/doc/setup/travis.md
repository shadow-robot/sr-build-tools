# Travis CI Server

## How to setup

The following repository can be used as an example of a [Travis CI](https://travis-ci.org/) configuration: [build servers check](https://github.com/shadow-robot/build-servers-check)

The process of setting up [Travis CI](https://travis-ci.org/) server:

  * In the root folder of your repository:
    * Copy *.travis.yml* from [build servers check](https://github.com/shadow-robot/build-servers-check) repository. 
    * Remove *after_failure* section.
    * Create *repository.rosinstall* in case you want to install some packages from source code. This file should be in [rosinstall](http://wiki.ros.org/rosinstall) format.
      You can use *repository.rosinstall* [build servers check](https://github.com/shadow-robot/build-servers-check) as an example.
  * *.travis.yml* contains a list of the modules which can be used in the **used_modules** variable. It can be adjusted to any amount of [modules needed](../modules.md).
  * Login to [Travis CI](https://travis-ci.org/) using GitHub account
  * Follow the simple process to add your repository to the projects list
  * Go to "Settings" tab in the top left corner of your project and set following values
    * **Build pushes** - *On* if you want to build every push on server or "Off" if you want to build pull requests only
    * **Build pull requests** - *On*
  * In order to post your code coverage results to [CodeCov](https://codecov.io) you need to add variable **CODECOV_TOKEN** in *Environment Variables* section of the *Settings*
  * You can use section *after_failure* from [build servers check](https://github.com/shadow-robot/build-servers-check) repository as an example of setting Slack notifications of the failed builds. 
    An variable **SLACK_WEB_HOOK_URL** needs to be defined in *Environment Variables* section of the *Settings*. 
    Please note that [Travis CI](https://travis-ci.org/) supports different [notification options](http://docs.travis-ci.com/user/notifications/) in configuration file *.travis.yml*. 
