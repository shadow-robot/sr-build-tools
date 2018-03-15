BRANCH=master
VERSION=kinetic

while [[ $# > 1 ]]
do
key="$1"

case $key in
    -b|--buildtoolsbranch)
    BRANCH="$2"
    shift # past argument
    ;;
    -v|--rosversion)
    VERSION="$2"
    shift # past argument
    ;;
    *)
    # unknown option
    ;;
esac
shift # past argument or value
done

echo "Installing Eepromtool"
wget -O /usr/bin/eepromtool https://github.com/shadow-robot/sr-build-tools/raw/$(echo $BRANCH | sed 's/#/%23/g')/bin/eepromtool
chmod +x /usr/bin/eepromtool

echo "Installing Gedit"
apt-get -y install gedit

echo "Installing Multiplot"
apt-get -y install ros-${VERSION}-rqt-multiplot

echo "Installing Multiplot Configs"
git clone https://github.com/shadow-robot/sr_multiplot_config.git --depth 1 /home/user/
chown -R $MY_USERNAME:$MY_USERNAME /home/user/sr_multiplot_config
