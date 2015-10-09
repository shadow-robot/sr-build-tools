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
----    * [Gradle](https://wiki.jenkins-ci.org/display/JENKINS/Gradle+Plugin)
----    * [Nested view](https://wiki.jenkins-ci.org/display/JENKINS/Nested+View+Plugin)
  * **sudo apt-get install docker.io -y**
  * in file */etc/sudoers* add following line **jenkins ALL=NOPASSWD: /usr/bin/docker** (jenkins is default user under which jenkins is running)
  * [generate ssh key pair](https://help.github.com/articles/generating-ssh-keys/) and put it into */var/lib/jenkins/.ssh* directory
  * restart Jenkins
  * set build name
  
### Setup job  
  
## Master-slave servers behind firewall
 
Scenario in which there is one master and multiple slaves involve few changes.
First of you need to install Jenkins as described in this [section](###Install Jenkins)

Now you need to create binding between master and slave hosts.
  * generate public and private keys pair 
 

## TODO
  !!! Check for private repositories !!!
  

