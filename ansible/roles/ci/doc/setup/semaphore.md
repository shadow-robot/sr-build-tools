# Semaphore Server

## How to setup

The following repository can be used as an example of a [Semaphore](https://semaphoreci.com/) configuration: [build servers check](https://github.com/shadow-robot/build-servers-check)

The process of setting up a [Semaphore](https://semaphoreci.com/) server:

  * In the root folder of your repository, create *repository.rosinstall* in case you want to install some packages from source code. This file should be in [rosinstall](http://wiki.ros.org/rosinstall) format.
      You can use *repository.rosinstall* [build servers check](https://github.com/shadow-robot/build-servers-check) as an example.
  * Go to [Semaphore](https://semaphoreci.com/) and create an account
  * Request support to add you to **Docker beta support**. After positive response proceed.
  * Follow the simple process to add your repository to the projects list.
  * On the "Project Setting" page, go to the tab "Build Settings" and set following values:
    * **Language** - *Python*
    * **Version** - *2.7*
    * **Build commands** - *All in Thread #1*
```bash
      export toolset_branch="master"
      export server_type="semaphore_docker"
      export used_modules="check_cache,check_build,code_style_check,unit_tests,check_deb,codecov_tool"
      export remote_shell_script="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/$toolset_branch/bin/sr-run-ci-build.sh"
      export encoded_url="$( echo "$remote_shell_script" | sed 's/#/%23/g' )"
      bash -c "$(wget -O - $encoded_url)" -- "$toolset_branch" $server_type $used_modules
```
      
      Variable **used_modules** contains list of the modules which can be used. It can be adjusted to any amount of the [modules needed](../modules.md).
  * On the "Project Setting" page select "Platform" tab and check "Ubuntu ... (beta with Docker support)" option.
  * To use [CodeCov](https://codecov.io) tool you need to encrypt variable **CODECOV_TOKEN** and put it into "Environment Variables" tab on "Project Setting" page. 
