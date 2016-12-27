#!/usr/bin/env bash

# Add local user
# Either use the LOCAL_USER_ID if passed in at runtime or
# fallback

USER_ID=${LOCAL_USER_ID:-9001}

usermod  --uid $USER_ID $MY_USERNAME
groupmod --gid $USER_ID $MY_USERNAME

export HOME=/home/$MY_USERNAME

exec /usr/local/bin/gosu $MY_USERNAME "$@"