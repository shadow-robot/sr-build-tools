#!/bin/bash

sr_build_tools_branch="F_%23SP-476_vs_code_setup_lint"
sr_build_tools_url="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/$sr_build_tools_branch"

# Check if VS Code is installed
if ! [ -x "$(command -v code)" ]; then
    echo 'VS Code is not installed. Installing...'
    # Check if wget is installed
    if ! [ -x "$(command -v wget)" ]; then
        echo 'wget is not installed. Installing...'
        sudo apt update || { echo "apt update failed!"; exit 1; }
        sudo apt install -y wget || { echo "apt install wget failed!"; exit 1; }
    echo "wget installed."
    fi
    wget -O /tmp/code.deb https://go.microsoft.com/fwlink/?LinkID=760868 || { echo "Failed to fetch VS Code!"; exit 1; }
    sudo apt install -y /tmp/code.deb || { echo "Failed to install VS Code!"; exit 1; }
    rm /tmp/code.deb
    echo "VS Code installed."
fi

# Install VS Code extensions
echo "Checking VS Code extensions..."
required_extensions=("GitHub.copilot" "ms-azuretools.vscode-docker" "ms-vscode-remote.remote-containers" "ms-vscode-remote.remote-ssh" "ms-vscode-remote.remote-ssh-edit" "ms-vscode.remote-explorer" "ms-vsliveshare.vsliveshare")
installed_extensions=$(code --list-extensions)
# Define array of extension names
for extension in "${required_extensions[@]}"; do
    if [[ $installed_extensions == *"$extension"* ]]; then
        continue
    else
        echo "Installing $extension..."
        code --install-extension $extension || { echo "Failed to install extension: \"$extension\"!"; exit 1; }
    fi
done
echo "All required VS Code extensions installed."

# Install container config
echo -e "\nSelect a container to install VS Code container config for:"
container_names=( "None" $(docker ps -a --format '{{.Names}}') )
select container_name in "${container_names[@]}"; do
    if [ "$container_name" = "None" ]; then
        echo "Not installing VS Code container config."
        break
    fi
    if [ -z "$container_name" ]; then
        echo "Invalid selection."
        continue
    fi
    image_name=$(docker inspect --format='{{.Config.Image}}' $container_name)
    echo "Container '$container_name' is image '$image_name'. Installing VS Code config for image..."
    # Replace colon with $2f to avoid issues with sed
    image_name=${image_name//:/\%2f}
    # Replace forward slash with $3f to avoid issues with sed
    image_name=${image_name//\//\%3f}
    container_config_file=~/.config/Code/User/globalStorage/ms-vscode-remote.remote-containers/imageConfigs/$image_name.json
    # Create directory if it doesn't exist
    mkdir -p $(dirname $container_config_file)
    wget -O "$container_config_file" "$sr_build_tools_url/ansible/roles/dev_machine/files/imageConfig.json" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Failed to fetch VS Code container config!"
        exit 1
    fi
    echo "VS Code container config installed to '$container_config_file'."
    break
done

# Set up SSH agent
echo -e "\nSetting up SSH agent to forward SSH credentials to the container..."
if [ -z "$SSH_AUTH_SOCK" ]; then
   # Check for a currently running instance of the agent
   RUNNING_AGENT="`ps -ax | grep 'ssh-agent -s' | grep -v grep | wc -l | tr -d '[:space:]'`"
   if [ "$RUNNING_AGENT" = "0" ]; then
        # Launch a new instance of the agent
        ssh-agent -s &> $HOME/.ssh/ssh-agent
   fi
   eval `cat $HOME/.ssh/ssh-agent`
fi
echo "SSH agent set up."

# Check if container is running
if [ -z "$container_name" ]; then
    echo "Not checking if container is running."
else
    if [ -z "$(docker ps -q -f name=$container_name)" ]; then
        echo "Container '$container_name' is not running."
        docker start $container_name || { echo "Failed to start container '$container_name'!"; exit 1; }
    else
        echo "Container '$container_name' is running."
    fi
    docker exec -it -u user $container_name bash -c "bash <(curl -s $sr_build_tools_url/ansible/roles/ros_workspace/files/vs_code/one_line_install.sh)"
fi

echo -e "\nTo use VS Code with a container, start the container, then run 'Remote-Containers: Attach to Running Container' command in VS Code. The first time you do this, VS Code Server and extensions will be installed in the container."
