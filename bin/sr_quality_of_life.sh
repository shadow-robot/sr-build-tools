#!/bin/bash

while [[ $# > 1 ]]
do
    key="$1"

    case $key in
        -u|--user)
            MY_USERNAME="$2"
            shift
            ;;
        -b|--bash_only)
            BASH_ONLY="$2"
            shift
            ;;
        *)
            # ignore unknown option
            ;;
    esac
    shift
done

if [ -z "${MY_USERNAME}" ]; then
    if [ -z "${USER}" ]; then
        MY_USERNAME="user"
    else
        MY_USERNAME="${USER}"
    fi
fi

if [ -z "${BASH_ONLY}" ]; then
	BASH_ONLY=false
fi

if [[ "${BASH_ONLY}" == false ]]; then

    echo "Installing and configuring additional quality-of-life tools"
    sudo apt install -y tree highlight speedometer xsel gosu screen

    echo "Configuring highlight"
    for new_lang in $(echo -e "launch\nxacro\nurdf"); do
        if [[ $(cat /etc/highlight/filetypes.conf | grep "Lang=\"xml\", Extensions=" | grep ${new_lang} | wc -l) -eq 0 ]]; then
            echo "Adding ${new_lang} as xml to highlight"
            cat /etc/highlight/filetypes.conf | sed -r 's/\{ Lang=\"xml\", Extensions=\{/\{ Lang=\"xml\", Extensions=\{\"'${new_lang}'\", /g' | sudo tee /etc/highlight/filetypes.conf
        fi
    done
    echo "Installing fzf"
    gosu $MY_USERNAME git clone --depth 1 https://github.com/junegunn/fzf.git /home/${MY_USERNAME}/.fzf
    gosu $MY_USERNAME /home/${MY_USERNAME}/.fzf/install --all
fi


echo "Grabbing additional bash cmds"
gosu $MY_USERNAME wget -O /home/${MY_USERNAME}/.bash_functions https://raw.githubusercontent.com/shadow-robot/sr-build-tools/F_add_useful_bash_stuff/docker/utils/additional_bashrc_commands_quality_of_life
if [[ $(cat /home/${MY_USERNAME}/.bashrc  | grep "source ~/.bash_functions" | wc -l) -eq 0 ]]; then
    echo "source ~/.bash_functions" >> /home/${MY_USERNAME}/.bashrc
fi
