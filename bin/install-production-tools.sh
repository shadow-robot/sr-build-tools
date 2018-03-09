echo "Installing Eepromtool"
cd /home/user/
wget https://github.com/shadow-robot/sr-build-tools/raw/${toolset_branch}/bin/eepromtool
chmod 700 /home/user/eepromtool
echo "Installing Gedit"
apt-get -y install gedit

echo "Installing Multiplot"
apt-get -y install ros-${ros-release-name}-rqt-multiplot

echo "Installing Multiplot Configs"
cd /home/user/
git clone https://github.com/shadow-robot/sr_multiplot_config.git --depth 1
chown -R $MY_USERNAME:$MY_USERNAME /home/user/sr_multiplot_config
