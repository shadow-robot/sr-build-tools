# Local Jenkins Server

## Single server behind firewall

### Install Jenkins

The following instructions can be used to setup single [Jenkins](https://jenkins-ci.org/) and build tools on your local server.

  * **sudo apt-get install jenkins -y**
  * open in browser http://<server_host>:8080/
  * [install]((https://wiki.jenkins-ci.org/display/JENKINS/Plugins#Plugins-Howtoinstallplugins)) following Jenkins plugins
    * [Git](https://wiki.jenkins-ci.org/display/JENKINS/Git+Plugin)
    * [JUnit](https://wiki.jenkins-ci.org/display/JENKINS/JUnit+Plugin)
    * [Cobertura](https://wiki.jenkins-ci.org/display/JENKINS/Cobertura+Plugin)
    * [Build Name Setter](https://wiki.jenkins-ci.org/display/JENKINS/Build+Name+Setter+Plugin)
  * **sudo apt-get install docker.io -y**
  * in file */etc/sudoers* add following line **jenkins ALL=NOPASSWD: /usr/bin/docker** (jenkins is default user under which jenkins is running)
  * generation of ssh key pair
    * **sudo su - jenkins** - login as jenkins user
    * follow these steps from [Github](https://help.github.com/articles/generating-ssh-keys/). 
      * Use empty pass phrase to make it run on Jenkins
      * Also it is recommended to setup separate account for Jenkins on Github. Use it to register ssh keys
  * restart Jenkins
  
### Setup job
  
Follow these steps to setup Jenkins job

  * select "Build a free-style software project" job type
  * Source Code Management
    * Git
    * Set path to repository (e.g. https://github.com/shadow-robot/sr_tools.git)
    * Credentials: username and password of your Jenkins account 
    * Branches to build: * (build all branches)
  * Build Triggers
    * Poll SCM: H/3 * * * * (every three minutes)
  * Build Environment
    * Set Build Name: #${BUILD_NUMBER}:${GIT_BRANCH}
  * Post-build Actions
    * Publish JUnit test result report
      * Test report XMLs: unit_tests/**/*.xml
    * Publish Cobertura Coverage Report
      * Cobertura xml report pattern: code_coverage/**/*.xml
      * In Advanced options uncheck "Fail builds if no reports"
  * Build
    * Execute shell

```bash
  export toolset_branch="master"
  export server_type="local"
  export used_modules="check_cache,code_coverage"
  
  export relative_job_path=${WORKSPACE#$HOME}
  
  export unit_tests_result_dir="$relative_job_path/unit_tests"
  export coverage_tests_result_dir="$relative_job_path/code_coverage"
  
  export remote_shell_script="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/$toolset_branch/bin/sr-run-ci-build.sh"
  curl -s "$( echo "$remote_shell_script" | sed 's/#/%23/g' )" | bash /dev/stdin "$toolset_branch" $server_type $used_modules $relative_job_path
```
  
Press Save button
  
## Master-slave servers behind firewall
 
### Setup master machine
 
Repeat all steps from this [section](#install-jenkins)


### Setting up slave machine

```bash

  export url="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/master/bin/sr-add-jenkins-slave.sh"
  bash -c "$(wget -O - $url)" -- <jenkins host name, jenkins by default> <jenkins sudo user, jenkins_sudo by default>

```

### Set binding between master and slave

Now you need to create binding between master and slave hosts.

  * Go to "Manage Jenkins" -> "Manage Nodes" menu in the Jenkins dashboard. 
  * Select "New Node" menu.
  * Fill following fields
    * Remote FS root: /home/jenkins/build
    * '# of executors': equals to number of the cores or processors
    * Usage: Utilize this slave as much as possible
    * Launch method: Launch slave agents on Unix machine via ssh 
    * Credentials: jenkins (choose from dropdown)
    * Availability: Keep this slave on-line as much as possible
  
Now you can setup jobs as described in the following [section](#setup-job)


## Best Practices

In order to setup jobs for multiple project quickly. You can setup one project based on this [section](#setup-job).
Afterwards you can use option to copy job during "New Item..." creation and change only repository path and names.

JUnit plugin is failing in case if there is no unit tests in the repository. So it is recommended to use it only when you have some tests.

