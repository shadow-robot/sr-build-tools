#!/usr/bin/env bash

Xvfb :0 &
export DISPLAY=:0

/usr/local/bin/entrypoint.sh "$@"
