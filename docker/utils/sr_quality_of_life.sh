#!/bin/bash

    echo "Installing and configuring additional quality-of-life tools" && \
    apt install -y tree highlight speedometer xsel && \
    cat /etc/highlight/filetypes.conf | sed -r 's/\{ Lang=\"xml\", Extensions=\{/\{ Lang=\"xml\", Extensions=\{\"launch\", /g' | tee /etc/highlight/filetypes.conf && \
    cat /etc/highlight/filetypes.conf | sed -r 's/\{ Lang=\"xml\", Extensions=\{/\{ Lang=\"xml\", Extensions=\{\"xacro\", /g' | tee /etc/highlight/filetypes.conf && \

    echo "Installing fzf" && \
    gosu $MY_USERNAME git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && \
    gosu $MY_USERNAME ~/.fzf/install --all && \
    \
