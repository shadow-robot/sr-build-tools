#!/usr/bin/env bash

# Add local user
# Either use the LOCAL_USER_ID and optionally LOCAL_GROUP_ID if passed in at runtime or
# fallback

USER_ID=${LOCAL_USER_ID:-9001}
GROUP_ID=${LOCAL_GROUP_ID:-$USER_ID}

export OLD_USER_ID=$(id -u $MY_USERNAME)
export OLD_GROUP_ID=$(id -g $MY_USERNAME)

usermod  --uid $USER_ID $MY_USERNAME
groupmod --gid $GROUP_ID $MY_USERNAME

export HOME=/home/$MY_USERNAME

find $HOME -user $OLD_USER_ID -exec chown -h $USER_ID {} \;
find $HOME -group $OLD_GROUP_ID -exec chgrp -h $GROUP_ID {} \;
usermod -g $GROUP_ID $MY_USERNAME

exec /usr/local/bin/gosu $MY_USERNAME "$@"
