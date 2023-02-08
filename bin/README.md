# sr-run-ci-build.sh
The following instructions run CI checks locally on a container

Download the latest sr-build-tools image from aws: ```docker pull public.ecr.aws/shadowrobot/build-tools:focal-noetic```

If it asks you for login then use the following command: ```aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/shadowrobot```

Create a temp container: ```docker run -it --rm --net=host --privileged -e DISPLAY -e QT_X11_NO_MITSHM=1 --gpus all -e NVIDIA_DRIVER_CAPABILITIES=all -e NVIDIA_VISIBLE_DEVICES=all -e LOCAL_USER_ID=$(id -u) -v /tmp/.X11-unix:/tmp/.X11-unix:rw public.ecr.aws/shadowrobot/build-tools:focal-noetic```
 
pull the latest sr-build-tools: ```cd sr-build-tools; git pull```

Clone the repository you want to test with: ```git clone --branch test_branch https://github.com/shadow-robot/sr_interface.git /home/user/workspace/src/sr_interface```

Make sure you replace the test_branch with the branch you want to test

Enter in bin folder: ```cd bin```

Now its time to run the check script: 
The arguments are: branch name of sr-build-tools, check type (local in our case), checks and local repository in our container
If the repository you want to check is a private one or contains private repos in its repository rosinstall file you need to export your github credentials like that:

```export GITHUB_LOGIN=your_username```

```export GITHUB_PASSWORD=your_password```

These will be lost when you exit the container

The available checks are

install check: *check_install*

Style Check: *code_style_check,check_license*

Code Coverage: *check_cache,code_coverage*

For example:
```sudo -E ./sr-run-ci-build.sh master local-docker check_cache,code_coverage /home/user/workspace/src/sr_interface```

The unit tests are stored here: ```/home/user/unit_tests```



# sr-code-style-check.sh

## Setup

You need to install Ansible in order to run this script.

Use following command to do so (it will install recent version in contrary to apt-get) 

```bash
sudo pip install ansible
```

## Usage

```bash
sr-code-style-check.sh <repository path (default: ./src)> <workspace path (default: .)> <code-style-check-type(default: code_style_check)>
```

## Results 

The results are written to *&lt;workspace&gt;/build/test_results/&lt;package_name&gt;* in XML format starting with *roslint* prefix.

## Examples

### All default parameters
```bash
 ~/workspaces/ros/sr-build-tools/bin/sr-code-style-check.sh
```

### Path to repository files and workspace specified
```bash
~/workspaces/ros/sr-build-tools/bin/sr-code-style-check.sh ~/workspaces/ros/shadow_ws/src/sr-visualization ~/workspaces/ros/shadow_ws
```

# Compile new rt-preempt kernel deb

## Install pre-requisites

```bash
sudo apt-get install git make gcc flex bison
git clone https://github.com/shadow-robot/sr-build-tools
```

## Prepare rt kernel

- Check available versions of rt preempt patch https://www.kernel.org/pub/linux/kernel/projects/rt
- Check corresponding kernel version https://www.kernel.org/pub/linux/kernel
- Edit `prepare_rt_kernel.sh` variables to fit the chosen versions
- Run `prepare_rt_kernel.sh`. It will open menuconfig, where you have to configure the preemption model.
- `General setup` -> `Preemption Model`  set to Fully Preemptible Kernel (RT)

## Compile and create deb

- Edit `create_rt_kernel_deb.sh` variable to fit the chosen version
- Run `create_rt_kernel_deb.sh` in the same directory where `prepare_rt_kernel.sh` was run

## Install kernel

- Run `sudo dpkg -i linux-*.deb` to install the deb packages

## Grub configuration

In order to be able to change between kernels at the system startup, go to `/etc/default/grub` file and make sure that `GRUB_HIDDEN_TIMEOUT` value is higher then zero or comment it out completely. If you made any changes to the file, before rebooting run `sudo update-grub`.

## Chose the kernel at the system startup
At the system startup, in the GRUB menu select `Advanced options for UBUNTU` and chose the rt kernel that you installed.

# Gather Changelog/gather_changelog.sh
This script has a few pre-requists as it is normally ran via a CodeBuild execution which store parameters in AWS.

Firstly you will need to have AWS CLI configured. you can do this by running `aws configure` and entering your Access Key and Secret Key as well as the Default Region as eu-west-2, you can leave the final value empty by just pressing enter.

You will then also have to set variables `GITHUB_LOGIN` and `GITHUB_PASSWORD`, the password you enter will need to be a token which has permission to pull all shadow-robot repos. To do this run:
```
export GITHUB_LOGIN="github_username"
export GITHUB_PASSWORD="github_token"
```

After this is done you can run the script. The gather_changelog.sh script has 3 needed parameters and one optional
1. Image Name: This is the URI of the image you want to get the changelog for (find examples [here](https://eu-west-2.console.aws.amazon.com/ecr/repositories?region=eu-west-2))
2. Image Tag: This is the tag of the image you want to gather the changelog for. It won't work with night-build or release tags, just ones like noetic-v0.0.1
3. Image Repository: This is the `Repository Name` field found [here](https://eu-west-2.console.aws.amazon.com/ecr/repositories?region=eu-west-2), it should match the URI of the image you used for the first parameter
4. (OPTIONAL) Image Tag Previous: If we ever have to re-publish old image or the script fails, we can use this Image Tag Previous field to manually select which two images we want to compare. If this value isn't present it will find the last chronological image tag that matches the same distribution tag.

**Example executions:**
Example with autoselected previous tag:
```
gather_changelog/gather_changelog.sh 080653068785.dkr.ecr.eu-west-2.amazonaws.com/shadow-dexterous-hand-glove noetic-v0.0.8 shadow-dexterous-hand-glove
```
Example with Optional 4th varible:
```
gather_changelog/gather_changelog.sh 080653068785.dkr.ecr.eu-west-2.amazonaws.com/shadow-dexterous-hand-glove noetic-v0.0.2 shadow-dexterous-hand-glove noetic-v0.0.1
```