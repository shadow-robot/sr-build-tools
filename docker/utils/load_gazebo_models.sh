#!/usr/bin/env bash

# Copyright 2022 Shadow Robot Company Ltd.
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

# Script is based on http://machineawakening.blogspot.com/2015/05/how-to-download-all-gazebo-models.html. It is improved
# in several ways. It avoids downloading all files and discarding unwanted ones by parsing the gazebo model manifest.
# It allows the specification of the user to set up, and models to fetch, e.g.:
# ./load_gazebo_modles.sh -u handuser -m ground_plane sun ambulance
# These two changes make it much faster and less of a load on the server. For backwards compatibility, no arguments
# results in all models being fetched.

tmp_dir="/tmp/models.gazebosim.org"
mkdir -p $tmp_dir
pushd $tmp_dir

function cleanup {
  echo "Cleaning up after gazebo model downloads..."
  popd
  rm -rf $tmp_dir
}

trap cleanup EXIT

GAZEBO_PATH="$HOME/.gazebo"

while getopts ':u:m:' opt; do
  case $opt in
    u) 
      if [[ ${OPTARG} == -* ]]; then
        echo "Missing argument for -${opt}"
        exit 1
      fi
      GAZEBO_USER_NAME="${OPTARG}"
      GAZEBO_PATH="/home/${GAZEBO_USER_NAME}/.gazebo"
      ;;
    m) MODEL_NAMES=("$OPTARG")
      until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [ -z $(eval "echo \${$OPTIND}") ]; do
        MODEL_NAMES+=($(eval "echo \${$OPTIND}"))
        OPTIND=$((OPTIND + 1))
      done
      ;;
    \?)
      echo "Invalid option: -${OPTARG}"
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

GAZEBO_MODELS_PATH="${GAZEBO_PATH}/models"
echo "Gazebo models will be downloaded to ${GAZEBO_MODELS_PATH}."

shift $(($OPTIND - 1))

echo "Fetching gazebo model list..."
model_list_url="http://models.gazebosim.org/manifest.xml"
model_list_xml=$(curl --retry 4 -s -f ${model_list_url})
if [ "$?" -ne 0 ]; then echo "Failed to fetch gazebo model list from ${model_list_url}."; exit 1; fi

echo "Parsing gazebo model list..."
regex='<uri>file:\/\/([^<]*)<\/uri>'
while read -r line; do
  if [[ $line =~ $regex ]]; then
    model_names+=("${BASH_REMATCH[1]}")
  fi
done <<< "$model_list_xml"
echo "${#model_names[*]} models on gazebo server."

if [ -z ${MODEL_NAMES+x} ]; then
  requested_models=${model_names[*]}
  echo "Downloading all models..."
else
  requested_models=${MODEL_NAMES[*]}
  echo "The following models were requested: $requested_models"
fi

mkdir models.gazebosim.org
cd models.gazebosim.org

for model_name in ${requested_models[@]}; do
  model_url="http://models.gazebosim.org/${model_name}/model.tar.gz"
  echo "Downloading ${model_url}..."
  mkdir $model_name
  cd $model_name
  wget $model_url >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Failed to download $model_url!"
    exit 1
  fi
  cd ..
done

for i in *
do
  tar -zvxf "$i/model.tar.gz" >/dev/null 2>&1
done

mkdir -p "$GAZEBO_MODELS_PATH"
if [ $? != 0 ]; then
  echo "Failed to create directory $GAZEBO_MODELS_PATH."
  exit 1
fi
cp -fR * "$GAZEBO_MODELS_PATH"
if [ $? != 0 ]; then
  echo "Failed to copy models to $GAZEBO_MODELS_PATH."
  exit 1
fi

if [ -n "${GAZEBO_USER_NAME+x}" ]; then
  chown -R ${GAZEBO_USER_NAME}:${GAZEBO_USER_NAME} ${GAZEBO_PATH}
  if [ $? != 0 ]; then
    echo "Failed to make ${GAZEBO_USER_NAME} the owner of $GAZEBO_PATH."
    exit 1
  fi
fi
