#!/usr/bin/env bash

set -e # Stop on errors
#set -x # echo commands

export jenkins_master_host=${1:-"jenkins"}
export jenkins_master_host_sudo_user=${2:-"jenkins_sudo"}
export jenkins_master_host_home=/var/lib/jenkins

export jenkins_user=jenkins
export jenkins_home="/home/$jenkins_user"
export jenkins_user_email="$jenkins_user@example.com"

apt-get update
apt-get install ssh git docker.io openjdk-7-jdk -y

#useradd -d "$jenkins_home" --create-home $jenkins_user
#mkdir "$jenkins_home/.ssh"
#chmod 700 "$jenkins_home/.ssh"

echo "Coping private key to local folder. Please provide passwords for Jenkins and local machines"
ssh -t $jenkins_master_host_sudo_user@$jenkins_master_host sudo -u jenkins scp $jenkins_master_host_home/.ssh/id_rsa $USER@$HOSTNAME:~
mv ~/id_rsa "$jenkins_home/.ssh"

echo "Coping public key to local folder. Please provide passwords for Jenkins and local machines"
ssh -t $jenkins_master_host_sudo_user@$jenkins_master_host sudo -u jenkins scp $jenkins_master_host_home/.ssh/id_rsa.pub $USER@$HOSTNAME:~
mv ~/id_rsa.pub "$jenkins_home/.ssh"

cp "$jenkins_home/.ssh/id_rsa.pub" "$jenkins_home/.ssh/authorized_keys"
chmod 600 "$jenkins_home/.ssh/authorized_keys"
chmod 400 "$jenkins_home/.ssh/id_rsa"
chown -R jenkins:jenkins "$jenkins_home/.ssh"

mkdir -v "$jenkins_home/build"
chown "$jenkins_user:$jenkins_user" "$jenkins_home/build"

echo "$jenkins_user  ALL=(ALL) NOPASSWD:  ALL" | (sudo EDITOR="tee -a" visudo)

su - $jenkins_user -c "git config --global user.name $jenkins_user"
su - $jenkins_user -c "git config --global user.email $jenkins_user_email"
