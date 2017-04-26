This Dockerfile is used for building a Docker Image with v4r library and is necessary for sr_recognizer package. In order to properly run a new container use `run.sh` file located in this folder.

In order to use recognizer service, get [sr_vision](https://github.com/shadow-robot/sr_vision) repository and run:
``` 
roslaunch sr_recognizer recognition_service.launch
```
In order to use client with blockly, get [sr_blockly](https://github.com/shadow-robot/sr_blockly) repository, run
```
roslaunch robot_blockly robot_blockly.launch block_packages:=[sr_blockly_blocks]
```
go to [this site](http://localhost:8000/pages/blockly.html) in your browser and connect `Which objects do you see` (located in Shadow Robot/Vision), `print` and `item` blocks. In `item` block click `rename variable` and set it to `result_names`. Blockly is now ready to launch.

In order to create a custom 3D mesh follow steps from [this site](https://www.evernote.com/shard/s240/sh/0d74e9e0-f5f7-4bd6-bb17-ed15c6e32bc9/9d74a9bfa86059ed81c7851b8f20056c)
