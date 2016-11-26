#!/usr/bin/env bash

# Add local user
# Either use the LOCAL_USER_ID if passed in at runtime or
# fallback

USER_ID=${LOCAL_USER_ID:-9001}

usermod  --uid $USER_ID $USERNAME
groupmod --gid $USER_ID $USERNAME

export HOME=/home/$USERNAME

exec /usr/local/bin/gosu $USERNAME "$@"