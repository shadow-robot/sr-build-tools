#!/bin/bash

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

# set -o xtrace

#this zips the contents of the given folder and uploads it to AWS, using the customerkey installed by oneliner inside the docker container
function fail {
  echo $1 >&2
  exit 1
}

function retry {
  local n=1
  local max=5
  local delay=15
  while true; do
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        echo "Upload failed. Attempt $n/$max:"
        sleep $delay;
      else
        fail "AWS failed to upload the logs after $n attempts."
      fi
    }
  done
}

print_usage(){
  echo "Usage: shadow_upload.sh <CUSTOMER_KEY> <INPUT_FOLDER_PATH> <TIMESTAMP>"
}

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]];then
  print_usage
  exit 0;
fi

CREDENTIALS_URL=https://5vv2z6j3a7.execute-api.eu-west-2.amazonaws.com/prod
CUSTOMERKEY=$1
INPUTFOLDERPATH=$2
TIMESTAMP=$3
CUSTOMERNAME="Unknown customer"

if [[ -z "$CUSTOMERKEY" ]] || [[ -z "$INPUTFOLDERPATH" ]] || [[ -z "$TIMESTAMP" ]]; then
  print_usage
  exit 1;
fi
MY_CURL=`which curl`
if [[ -z "$MY_CURL" ]]; then
  echo "curl utility is required to run this script"
  exit 1;
fi

response=`$MY_CURL --silent -H "x-api-key: $CUSTOMERKEY" $CREDENTIALS_URL`
if [[ $response = *"forbidden"* ]];then
  echo "Access is forbidden. Check the correctness of the customer key or contact Shadow Robot Company support."
  print_usage
  return 1;
fi
if [[ $response != *"SESSION_TOKEN"* ]];then
  echo "Unable to get temporary credentials. Read the following message to figure out the root cause or contact Shadow Robot Company support."
  retry $MY_CURL -verbose -H "x-api-key: $CUSTOMERKEY" $CREDENTIALS_URL
  print_usage
  return 1;
fi

ACCESS_KEY_ID=`echo -e "$response" | grep ACCESS_KEY_ID | sed 's/ACCESS_KEY_ID=//'`
SECRET_ACCESS_KEY=`echo -e "$response" | grep SECRET_ACCESS_KEY | sed 's/SECRET_ACCESS_KEY=//'`
SESSION_TOKEN=`echo -e "$response" | grep SESSION_TOKEN | sed 's/SESSION_TOKEN=//'`
UPLOAD_URL=`echo -e "$response" | grep URL | sed 's/URL=//'`
CUSTOMERNAME=`echo -e "$response" | grep CUSTOMER_NAME | sed 's/CUSTOMER_NAME=//'`

CUSTOMERNAME=`echo -e "$CUSTOMERNAME" | sed 's/ /-/g'`
TIMESTAMP=`echo -e "$TIMESTAMP" | sed 's/:/-/g'`

export AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID; \
export AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY; \
export AWS_SESSION_TOKEN=$SESSION_TOKEN; \

#max compression

env GZIP=-9 tar cvzf "$INPUTFOLDERPATH/../${CUSTOMERNAME}_${TIMESTAMP}.tar.gz" $INPUTFOLDERPATH > /dev/null 2>&1
retry /usr/local/bin/aws s3 cp "$INPUTFOLDERPATH/../${CUSTOMERNAME}_${TIMESTAMP}.tar.gz" $UPLOAD_URL > /dev/null 2>&1
echo "ok"
exit 0
