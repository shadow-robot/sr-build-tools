This folder contains an adaptation of [Ubuntu Pi Flavour Maker](http://ubuntu-pi-flavour-maker.org/), originally created by Martin Wimpress. Source and scripts were cloned from [the launchpad reposository](https://launchpad.net/ubuntu-pi-flavour-maker).

If you want to build a Pi image (with docker engine installed or otherwise) your best bet is to pull our Docker image, which contains everything in this folder, and everything required to run it. This will give you a predictable, consistent build process.

You could clone this repo to your machine and run the script there, but you will probably face a few iterations of failed runs and dependency installations.

# Build an Image Using Docker (Recommended)
This is by far the easiest approach.

1. On your docker host terminal:
    1. `docker pull shadowrobot/ubuntu-pi-flavour-maker`
    2. `docker run --rm -it -v ~/PiFlavourMaker:/root/PiFlavourMaker --privileged shadowrobot/ubuntu-pi-flavour-maker`
    
        You can replace `~/PiFlavourMaker` with some other path on your local system; this is where the resulting build and .img files will be saved.
2. On the resulting docker container terminal:
    1. `./build.sh <flavour>`
    
        Where `<flavour>` is any of the following:
        - ubuntu
        - ubuntu-minimal
        - ubuntu-standard
        - ubuntu-mate (recommended for a generic desktop)
        - ubuntu-gnome
        - kubuntu
        - lubuntu
        - xubuntu
        - docker (ubuntu-minimal with a few fixes and docker installed)
        - some other flavour for which you have generated a `build-settings-<flavour>.sh` file

After a (significant) delay, `~/PiFlavourMaker` on your host machine (or a different folder that you specified in step 1.2) will contain the results of the build, including a .img file, ready to be written to an SD card for use in a Raspberry Pi.

