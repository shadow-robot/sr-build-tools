Tests the glassbot ansible role using a vagrant vm.

Note that due to the glassbot repo being private we need a some tricks to install the code from github. The user running
the playbook needs to have a key loaded in there key agent with github access and keyforwarding active.

If this isn't working provision will hand on:
```
TASK: [ros_workspace | Install ../data/glassbot-hydro.rosinstall] *************
```

To make sure you have the key loaded run:
```sh
ssh-add -l
```

You should see you key listed. To test the forward, login over ssh and run the same command:
```sh
vagrant ssh
ssh-add -l
```

You should see the same key listed. If not forwarding isn't working. The easyest way to active is to add this to your ~/.ssh/config
```
Hosts *
    ForwardAgent yes
```

You may also need to run the clone manually once to confirm the ssh host key.
```sh
vagrant ssh
cd /tmp
git clone git@github.com:shadow-robot/glassbot.git
rm -r glassbot
```

