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
 
Scenario in which there is one master and multiple slaves involve few changes.
First of all you need to install Jenkins as described in this [section](###Install Jenkins)

Next you need to execute following commands
```bash
  sudo su - jenkins # login as jenkins user
 
  # create soft links for keys in ~/userContent. This is needed for slave machines setup 
  cd ~/userContent/
  
  # link public key
  ln -s ../.ssh/id_rsa.pub .
  
  # also link private key because User needs it to login into github
  ln -s ../.ssh/id_rsa .
  
  # now you can access public key by following URL http://<jenkins_server>:8080/userContent/id_rsa.pub
```


### Setting up slave machine

```bash
  export jenkins_user=jenkins
  export jenkins_home="/home/$jenkins_user"
  export jenkins_url=<YOUR_JENKINS_HOST>:8080
  export jenkins_user_email="$jenkins_user@example.com"
  export server_pubkey="http://$jenkins_url/userContent/id_rsa.pub"
  # User needs the private key to login into github
  export server_privatekey="http://$jenkins_url/userContent/id_rsa"
  
  sudo useradd -d "$jenkins_home" --create-home $jenkins_user
  sudo mkdir "$jenkins_home/.ssh"
  sudo chmod 700 "$jenkins_home/.ssh"
  
  sudo wget -O "$jenkins_home/.ssh/authorized_keys" "$server_pubkey"
  sudo chmod 600 "$jenkins_home/.ssh/authorized_keys"
  sudo chown -R jenkins:jenkins "$jenkins_home/.ssh"

  sudo wget -O "$jenkins_home/.ssh/id_rsa" "$server_privatekey"
  sudo chmod 400 "$jenkins_home/.ssh/id_rsa"
  sudo chown $jenkins_user:$jenkins_user "$jenkins_home/.ssh/id_rsa"
  sudo wget -O "$jenkins_home/.ssh/id_rsa.pub" "$server_pubkey"
  sudo chown $jenkins_user:$jenkins_user "$jenkins_home/.ssh/id_rsa.pub"
 
  sudo mkdir -v "$jenkins_home/build"
  sudo chown "$jenkins_user:$jenkins_user" "$jenkins_home/build"
```
  Add to /etc/sudoers following line "$jenkins_user  ALL=(ALL) NOPASSWD:  ALL"

```bash
  sudo apt-get update 
  sudo apt-get install openssh-server ssh git docker.io openjdk-7-jdk -y

  sudo su - $jenkins_user -c "git config --global user.name $jenkins_user"
  sudo su - $jenkins_user -c "git config --global user.email $jenkins_user_email"
  
  sudo su - jenkins
  ssh -T git@github.com # type "yes" to accept GitHub keys
  exit

```

Now you can hide private key on master machine
```bash
  sudo su - jenkins # login as jenkins user
  rm ~/userContent/id_rsa
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
  
