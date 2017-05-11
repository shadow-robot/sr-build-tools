#!/usr/bin/env bash

/usr/local/bin/entrypoint.sh

Xvfb :0 &
export DISPLAY=:0
