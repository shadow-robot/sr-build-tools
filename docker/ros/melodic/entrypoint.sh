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

# Add local user
# Either use the LOCAL_USER_ID and optionally LOCAL_GROUP_ID if passed in at runtime or
# fallback

USER_ID=${LOCAL_USER_ID:-9001}
GROUP_ID=${LOCAL_GROUP_ID:-$USER_ID}

export HOME=/home/$MY_USERNAME

export OLD_USER_ID=$(id -u $MY_USERNAME)

if [ $OLD_USER_ID -ne $USER_ID ]
then
  usermod  --uid $USER_ID $MY_USERNAME
  find $HOME -user $OLD_USER_ID -exec chown -h $USER_ID {} \;
fi

export OLD_GROUP_ID=$(id -g $MY_USERNAME)

if [ $OLD_GROUP_ID -ne $GROUP_ID ]
then
  groupmod --gid $GROUP_ID $MY_USERNAME
  find $HOME -group $OLD_GROUP_ID -exec chgrp -h $GROUP_ID {} \;
  usermod -g $GROUP_ID $MY_USERNAME
fi

if mkdir -p /home/$MY_USERNAME/.ros/log/core_dumps ; then
    chown -R $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/.ros/log/core_dumps
    chown -R $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/.ros/log
fi
echo 1 > /proc/sys/kernel/core_uses_pid
ulimit -c unlimited
echo 1 > /proc/sys/fs/suid_dumpable
echo /home/$MY_USERNAME/.ros/log/core_dumps/core_BOF_%e_EOF_%p.%h.%t > /proc/sys/kernel/core_pattern

exec /usr/local/bin/gosu $MY_USERNAME "$@"
