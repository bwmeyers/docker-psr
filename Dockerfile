FROM ubuntu:14.04.4
MAINTAINER Bradley Meyers <bradley.meyers1993@gmail.com>

WORKDIR /home

RUN echo 'deb http://us.archive.ubuntu.com/ubuntu trusty main multiverse' >> /etc/apt/sources.list
RUN apt-get update -y
RUN apt-get install -y make gcc emacs gedit libcfitsio3 libcfitsio3-dev pgplot5 wget libgsl0-dev python python-pip python-numpy python-scipy python-matplotlib ipython x11-apps x11-utils gfortran git libglib2.0-dev pkg-config libxml2 libxml2-dev tcsh cmake ftp csh build-essential libtool gsl-bin gnuplot gnuplot-x11 libblas3 liblapack3 libblas-dev liblapack-dev libpng12-dev autoconf automake m4 swig libx11-dev vim locate libfftw3-dev libfftw3-doc

# link cfitsio libraries
RUN ln -s /usr/lib/x86_64-linux-gnu/libcfitsio.so /usr/lib/x86_64-linux-gnu/libcfitsio.so.0


# setup directory structure
RUN mkdir /home/pulsar-software


# create pulsar software home env. variable
ENV PSRHOME /home/pulsar-software


# download fftw3 source code and build it -- only if we need to other wise currently using Ubuntu version
#RUN cd $PSRHOME && mkdir fftw3-build && cd fftw3-build && wget http://www.fftw.org/fftw-3.3.4.tar.gz && tar xvfz fftw-3.3.4.tar.gz
#RUN cd $PSRHOME/fftw3-build/fftw-3.3.4 && ./configure --prefix=$PSRHOME --enable-shared --enable-threads --enable-float && make && make install && make clean 
#RUN cd $PSRHOME/fftw3-build/fftw-3.3.4 && ./configure --prefix=$PSRHOME --enable-shared --enable-threads && make && make install && make clean


# download pulsar software from git repositories
RUN cd $PSRHOME && git clone git://git.code.sf.net/p/psrchive/code psrchive && git clone git://git.code.sf.net/p/tempo/tempo && git clone https://bitbucket.org/psrsoft/tempo2.git && git clone git://github.com/scottransom/presto.git && git clone git://git.code.sf.net/p/dspsr/code dspsr


# change into $PSRHOME and get PSRCAT
RUN cd $PSRHOME && wget http://www.atnf.csiro.au/people/pulsar/psrcat/downloads/psrcat_pkg.tar.gz && tar xvfz psrcat_pkg.tar.gz && cd psrcat_tar && bash makeit
RUN cd $PSRHOME && mv psrcat_tar psrcat


# python variables for easy access 
ENV PYTHONBASE /usr/lib/local
ENV PYTHONVER 2.7


# PGPLOT variables
ENV PGPLOT_DIR /usr/lib
ENV PGPLOT_FONT $PGPLOT_DIR/pgplot5/grfont.dat
ENV PGPLOT_RGB $PGPLOT_DIR/pgplot5/rgb.dat
ENV PGPLOT_DEV /xs


# pulsar software locations
ENV PSRCHIVE $PSRHOME/psrchive
ENV DSPSR $PSRHOME/dspsr
ENV PRESTO $PSRHOME/presto
ENV TEMPO $PSRHOME/tempo
ENV TEMPO2 $PSRHOME/tempo2


# PSRCAT database location
ENV PSRCAT_FILE $PSRHOME/psrcat/psrcat.db

# path variables
ENV PATH $PSRHOME/bin:$PRESTO/bin:$PYTHONBASE/bin:$PSRHOME/psrcat:$PATH
ENV PYTHONPATH $PSRHOME/lib/python$PYTHONVER/site-packages:$PRESTO/lib/python:$PYTHONBASE/lib/python$PYTHONVER:$PYTHONBASE/lib/python$PYTHONVER/site-packages
ENV LD_LIBRARY_PATH $PSRHOME/lib:$PRESTO/lib:$TEMPO2/lib:$PYTHONBASE/lib
ENV LIBRARY_PATH $PSRHOME/lib:$PRESTO/lib:$TEMPO2/lib:$PYTHONBASE/lib
ENV PKG_CONFIG_PATH /usr/lib/x86_64-linux-gnu:$PKG_CONFIG_PATH



#################
## BUILD TEMPO ##
#################

RUN cd $TEMPO && wait && ./prepare && wait && ./configure F77=gfortran --prefix=$PSRHOME && make && make install

# edit the obsys.dat database to contain the MWA's position
RUN cd $TEMPO/ && echo "-2559454.08    5095372.14      -2849057.18     1  MWA                 k  MA" >> obsys.dat


##################
## BUILD TEMPO2 ##
##################

RUN cd $TEMPO2 && wait && ./bootstrap ; ./bootstrap && wait && ./configure F77=gfortran --prefix=$PSRHOME CXXFLAGS="-I$PSRHOME/include -I$PGPLOT_DIR" LDFLAGS=-L$PGPLOT_DIR && make && make install && make plugins && make plugins-install && make clean

# edit the observatories.dat database to contain the MWA's position
RUN cd $TEMPO2/T2runtime/observatory && echo "-2559454.08    5095372.14      -2849057.18       MWA                 mwa" >> observatories.dat


####################
## BUILD PSRCHIVE ##
####################

RUN cd $PSRCHIVE && wait && ./bootstrap ; ./bootstrap && wait && ./configure F77=gfortran --prefix=$PSRHOME --enable-shared && make && make check && make install && make clean


#################
## BUILD DSPSR ##
#################

RUN cd $DSPSR && echo "apsr asp bcpm bpsr cpsr cpsr2 gmrt lbadr lbadr64 mark4 mark5 maxim mwa pdev pmdaq puma2 s2 sigproc vdif fits" > backends.list
RUN cd $DSPSR && wait && ./bootstrap ; ./bootstrap && wait && ./configure F77=gfortran --prefix=$PSRHOME LDFLAGS=-L$PGPLOT_DIR && make && make install && make clean


##################
## BUILD PRESTO ##
################## PRESTO is slightly more involved and requires some editing in the Makefile and python setup files

# change the Makefile to point explicitly where the approriate libraries are found
#RUN cd $PRESTO/src && cat Makefile | sed 's;FFTINC := $(shell pkg-config --cflags fftw3f);FFTINC = -I$($PSRHOME)/include;g' | sed 's;FFTLINK := $(shell pkg-config --libs fftw3f);FFTLINK = -L$(PSRHOME)/lib -lfftw3f;g' > Makefile_2 && mv Makefile Makefile_original && mv Makefile_2 Makefile

# alter some of the source code to specifically allow the usage of the MWA
RUN cd $PRESTO/src && sed -i "/strcpy(outname, "LWA1");/a} else if (strcmp(scope, "mwa") == 0 ) {\nstrcpy(obscode, "MW");\nstrcpy(outname, "MWA128T");" misc_utils.c
RUN cd $PRESTO/src && sed -i "/} else if (strcmp(idata->telescope, "SRT") == 0) {/i} else if (strcmp(idata->telescope, "MWA") == 0) {\nscopechar = 'k';\ntracklen = 12;" polycos.c

RUN cd $PRESTO/src && make makewisdom && make prep && make && make clean


# change the python setup scripts to inlcude appropriate compile pointers
RUN cd $PRESTO/python && mv setup.py setup_orig.py && cat setup_orig.py | sed 's;include_dirs = \[\];include_dirs = \["/home/pulsar-software/include"\];g' | sed 's;ppgplot_libraries = \["cpgplot", "pgplot", "X11", "png", "m"\];ppgplot_libraries = \["cpgplot", "pgplot", "X11", "png", "m", "gfortran"\];g' | sed 's;ppgplot_library_dirs = \["/usr/X11R6/lib"\];ppgplot_library_dirs = \["/usr/lib"\];g' |  sed 's;presto_library_dirs = \[\];presto_library_dirs = \["/home/pulsar-software/lib","/home/pulsar-software/presto/lib"\];g' > setup.py

RUN cd $PRESTO/python && mv setup_ppgplot.py setup_ppgplot_original.py && cat setup_ppgplot_original.py | sed 's;ppgplot_libraries = \["cpgplot", "pgplot", "X11", "png", "m", "g2c"\];ppgplot_libraries = \["cpgplot", "pgplot", "X11", "png", "m", "g2c", "gfortran"\];g' | sed 's;ppgplot_library_dirs = \["/usr/X11R6/lib"\];ppgplot_library_dirs = \["/usr/lib"\];g' > setup_ppgplot.py

RUN cd $PRESTO/python && make && make clean




ENTRYPOINT /bin/bash