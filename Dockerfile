FROM ubuntu:14.04.4
MAINTAINER Bradley Meyers <bradley.meyers1993@gmail.com>

WORKDIR /home

RUN echo 'deb http://us.archive.ubuntu.com/ubuntu trusty main multiverse' >> /etc/apt/sources.list
RUN apt-get update -y
RUN apt-get install -y make gcc emacs gedit libcfitsio3 libcfitsio3-dev pgplot5 wget libgsl0-dev python python-pip python-numpy python-scipy python-matplotlib ipython x11-apps x11-utils gfortran git libglib2.0-dev pkg-config libxml2 libxml2-dev tcsh cmake ftp csh build-essential libtool gsl-bin gnuplot gnuplot-x11 libblas3 liblapack3 libblas-dev liblapack-dev libpng12-dev autoconf automake m4 swig libx11-dev vim locate


# link cfitsio libraries
RUN ln -s /usr/lib/x86_64-linux-gnu/libcfitsio.so /usr/lib/x86_64-linux-gnu/libcfitsio.so.0


# setup directory structure
RUN mkdir /home/pulsar-software


# create pulsar software home env. variable
ENV PSRHOME /home/pulsar-software


# change into $PSRHOME and download fftw3 source code
RUN cd $PSRHOME && mkdir fftw3-build && cd fftw3-build && wget http://www.fftw.org/fftw-3.3.4.tar.gz && tar xvfz fftw-3.3.4.tar.gz


# change into $PSRHOME and download pulsar software from git
RUN cd $PSRHOME && git clone git://git.code.sf.net/p/psrchive/code psrchive && git clone git://git.code.sf.net/p/tempo/tempo && git clone https://bitbucket.org/psrsoft/tempo2.git && git clone git://github.com/scottransom/presto.git && git clone git://git.code.sf.net/p/dspsr/code dspsr


# change into $PSRHOME and get PSRCAT
RUN cd $PSRHOME && wget http://www.atnf.csiro.au/people/pulsar/psrcat/downloads/psrcat_pkg.tar.gz && tar xvfz psrcat_pkg.tar.gz && cd psrcat_tar && bash makeit


# python variables for easy access 
ENV PYTHONBASE /usr/lib/local
ENV PYTHONVER 2.7


# PGPLOT variable
ENV PGPLOT_DIR /usr/lib
ENV PGPLOT_FONT $PGPLOT_DIR/pgplot5/grfont.dat
ENV PGPLOT_RGB $PGPLOT_DIR/pgplot5/rgb.dat


# individual pulsar software locations
ENV PSRCHIVE $PSRHOME/psrchive
ENV DSPSR $PSRHOME/dspsr
ENV PRESTO $PSRHOME/presto
ENV TEMPO $PSRHOME/tempo
ENV TEMPO2 $PSRHOME/tempo2


# PSRCAT database location
ENV PSRCAT_FILE $PSRHOME/psrcat_tar/psrcat.db

# path variables
ENV PATH $PSRHOME/bin:$PRESTO/bin:$PYTHONBASE/bin:$PSRHOME/psrcat_tar:$PATH
ENV PYTHONPATH $PSRHOME/lib/python$PYTHONVER/site-packages:$PRESTO/lib/python:$PYTHONBASE/lib/python$PYTHONVER:$PYTHONBASE/lib/python$PYTHONVER/site-packages
ENV LD_LIBRARY_PATH $PSRHOME/lib:$PRESTO/lib:$TEMPO2/lib:$PYTHONBASE/lib
ENV LIBRARY_PATH $PSRHOME/lib:$PRESTO/lib:$TEMPO2/lib:$PYTHONBASE/lib

# MWA compat
#RUN echo '-2559454.08    5095372.14      -2849057.18     1  MWA                 k  MA' >> $TEMPO/obsys.dat
#RUN echo '-2559454.08    5095372.14      -2849057.18       MWA                 mwa' >> $TEMPO2/observatory/observatories.dat





ENTRYPOINT /bin/bash