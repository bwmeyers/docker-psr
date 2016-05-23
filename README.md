# docker-psr for the MWA (a.k.a. "mwa-pulsar-stack")
Builds a docker image for a standard set of pulsar analysis packages, with addition for the MWA which are currently not included in the standard software releases (yet). Currently, this is mostly taken from an existing set of binaries built on Ubuntu 14.04 and bundled into a tar file. Ultimately, we'd like to properly build from source for all packages and trigger docker builds from github pushes.

# Goal
Like most applied software, pulsar software is heterogeneous and challenging to build. Docker can ease the introduction of new users and allow new use cases, like cloud computing.

# Includes
- tempo
- tempo2
- psrchive
- dspsr
- presto
- psrcat
- all their dependencies (pgplot5, fftw, etc)
- standard python

You'll find the pulsar software in /home/pulsar-software and environment variables as typical. 

# Using
To build your own version, after forking this repo or the original (https://github.com/caseyjlaw/docker-psr) and pulling:

    docker build -t bwmeyers/mwa-pulsar-stack .

To run the image available in docker hub:

    docker run -i -t bwmeyers/mwa-pulsar-stack bash

You can mount your data directory into the docker container with the -v flag, so:

    docker run -i -t -v /path/to/local/directory:/data bwmeyers/mwa-pulsar-stack bash

This will drop you in to an Ubuntu 14.04 OS with bash shell with all data in /data. Be careful as any data removed from /data in the container will also be removed from the local directory which you mounted to /data.

To get x11 tunneling working nicely, so you can see the usual PGPLOT outputs, you'll need to use the following:

   `docker run -i -t --rm -e DISPLAY=$DISPLAY -u $(id -u) -v /tmp/.X11-unix:/tmp/.X11-unix:ro bwmeyers/mwa-pulsar-stack bash`

Please read the Docker documentation to make sure the above is suitable for you system/network. In the above run, you will no longer have full root premissions.

New users may also find "docker do" useful to run pulsar tools without interactively running bash in a container. See https://github.com/deepgram/sidomo for more info.

The docker hub for this mwa-pulsar-stack can be found here: https://hub.docker.com/r/bwmeyers/mwa-pulsar-stack/

# Issues

Report problems to bradley.meyers1993@gmail.com  
