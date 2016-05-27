#!/bin/bash

OPENNI_FILE="OpenNI-Linux-x64-2.2.0.33.tar.bz2"
OPENNI_DIR="OpenNI-Linux-x64-2.2"
NITE_FILE="NiTE-Linux-x64-2.2.tar1.zip"
NITE_INNER_FILE="NiTE-Linux-x64-2.2.tar.bz2"
NITE_DIR="NiTE-Linux-x64-2.2"

mkdir -p ~/lib
cd ~/lib
if [ -d "${OPENNI_DIR}" ]; then
  rm -rf ${OPENNI_DIR}
fi
if [ -d "${NITE_DIR}" ]; then
  rm -rf ${NITE_DIR}
fi

echo "-   Downloading OpenNI2 ..."

r= `wget -q http://com.occipital.openni.s3.amazonaws.com/${OPENNI_FILE}`
if [ $? -ne 0 ]
  then echo "-   Failed to download, please check your internet connection!"
  exit
  else echo "-   Done"
fi
echo -e "-   Downloading NiTe2, this may take a while ..."

r= `wget -q http://download.dahoo.fr/Ressources/openNi/last%20version%20Nite/${NITE_FILE}`
if [ $? -ne 0 ]
  then echo "-   Failed to download, please check your internet connection!" exit
  else echo "-   Done"
fi

echo "-   Unzipping ..."
tar jxf ${OPENNI_FILE}
unzip ${NITE_FILE}

tar jxf ${NITE_INNER_FILE}
rm ${NITE_INNER_FILE} ${NITE_FILE} ${OPENNI_FILE} 
echo "-   Done"

cd ${OPENNI_DIR}/
echo "-   Please enter passward for installation" 
sudo ./install.sh
filename="OpenNIDevEnvironment"

echo "#  OpenNI2 & NiTe2 env setup" >> ~/.bashrc
while read -r line
do
    name="$line"
    echo "-   Adding to .bashrc : $name"
    echo $name >> ~/.bashrc

done < "$filename"

cd ..
cd ${NITE_DIR}/
sudo ./install.sh
filename="NiTEDevEnvironment"
while read -r line
do
    name="$line"
    echo "-   Adding to .bashrc : $name"
    echo $name >> ~/.bashrc

done < "$filename"

cd Redist/NiTE2/
ln -s `pwd` ~/.ros/NiTE2

# This seems to be necessary to avoid error "DeviceOpen using default: no devices found"
sudo ln -s /lib/x86_64-linux-gnu/libudev.so.1.3.5 /lib/x86_64-linux-gnu/libudev.so.0

echo "Installation success. Please source .bashrc"
