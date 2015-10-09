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
      * Also you might want to setup separate account for Jenkins on Github. Use it to register ssh keys
  * restart Jenkins
  
### Setup job
  
  * set build name

  
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
  
  sudo apt-get install docker.io -y
  useradd -d "$jenkins_home" --create-home $jenkins_user
  mkdir "$jenkins_home/.ssh"
  chmod 700 "$jenkins_home/.ssh"
  
  wget -O "$jenkins_home/.ssh/authorized_keys" "$server_pubkey"
  chmod 600 "$jenkins_home/.ssh/authorized_keys"
  chown -R jenkins:jenkins "$jenkins_home/.ssh"

  wget -O "$jenkins_home/.ssh/id_rsa" "$server_privatekey"
  chmod 400 "$jenkins_home/.ssh/id_rsa"
  chown $jenkins_user:$jenkins_user "$jenkins_home/.ssh/id_rsa"
  wget -O "$jenkins_home/.ssh/id_rsa.pub" "$server_pubkey"
  chown $jenkins_user:$jenkins_user "$jenkins_home/.ssh/id_rsa.pub"
 
  mkdir -v "$jenkins_home/build"
  chown "$jenkins_user:$jenkins_user" "$jenkins_home/build"

  sudoers-add "$jenkins_user  ALL=(ALL) NOPASSWD:  ALL"
  su - $jenkins_user -c "git config --global user.name $jenkins_user"
  su - $jenkins_user -c "git config --global user.email $jenkins_user_email"

  sudo apt-get update 
  sudo apt-get install ssh git docker.io -y
```

Now you can hide private key on master machine
```bash
  sudo su - jenkins # login as jenkins user
  rm ~/userContent/id_rsa
``` 
 

### Set binding between master and slave
Now you need to create binding between master and slave hosts.


## TODO
  !!! Check for private repositories !!!
  

