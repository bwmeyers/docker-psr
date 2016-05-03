FROM ubuntu:14.04.4
MAINTAINER Bradley Meyers <bradley.meyers1993@gmail.com>

WORKDIR /home

RUN echo 'deb http://us.archive.ubuntu.com/ubuntu trusty main multiverse' >> /etc/apt/sources.list
RUN apt-get update -y && apt-get install -y make gcc emacs libcfitsio3 libcfitsio3-dev pgplot5 wget \
    libgsl0-dev python python-pip python-numpy python-scipy python-matplotlib ipython x11-apps gfortran git \
    libglib2.0-dev pkg-config libxml2 libxml2-dev tcsh



RUN cd /usr/local && wget https://storage.googleapis.com/student_tools/pulsar64.tar.gz && tar xvfz pulsar64.tar.gz
RUN cd / && wget https://storage.googleapis.com/student_tools/sigproc.tar.gz && tar xvfz sigproc.tar.gz
RUN ln -s /usr/lib/x86_64-linux-gnu/libcfitsio.so /usr/lib/x86_64-linux-gnu/libcfitsio.so.0
RUN wget http://www.atnf.csiro.au/people/pulsar/psrcat/downloads/psrcat_pkg.tar.gz && tar xvfz psrcat_pkg.tar.gz && cd psrcat_tar && bash makeit 
RUN cp /home/psrcat_tar/psrcat /usr/local/pulsar64/bin/psrcat && cp /home/psrcat_tar/psrcat.db /usr/local/pulsar64/include/psrcat.db


ENV PSR64 /usr/local/pulsar64
ENV PYTHONBASE /usr/lib/local
ENV PYTHONVER 2.7
ENV PGPLOT_DIR /usr/lib64/pgplot
ENV PRESTO $PSR64/src/presto
ENV TEMPO $PSR64/src/tempo
ENV TEMPO2 $PSR64/share/tempo2
ENV PATH $PSR64/bin:$PRESTO/bin:$PYTHONBASE/bin:/usr/local/sigproc/bin:$PATH
ENV PYTHONPATH $PSR64/lib/python$PYTHONVER/site-packages:$PRESTO/lib/python:$PYTHONBASE/lib/python$PYTHONVER:$PYTHONBASE/lib/python$PYTHONVER/site-packages
ENV LD_LIBRARY_PATH $PSR64/lib:$PRESTO/lib:$TEMPO2/lib:$PYTHONBASE/lib
ENV LIBRARY_PATH $PSR64/lib:$PRESTO/lib:$TEMPO2/lib:$PYTHONBASE/lib
ENV CPATH /usr/local/include
ENV PSRCAT_FILE /usr/local/pulsar64/include/psrcat.db
ENV PKG_CONFIG_PATH /usr/local/pulsar64/src/fftw-3.3.4

# rebuild presto
RUN git clone http://github.com/caseyjlaw/presto.git && cd presto
RUN cd presto/src && awk '{if ($1=="FFTINC") printf("FFTINC = -I/usr/local/pulsar64/include\n"); else print $0}' Makefile > Makefile2
RUN cd presto/src && mv Makefile2 Makefile && make


# MWA compat
RUN echo '-2559454.08    5095372.14      -2849057.18     1  MWA                 k  MA' >> $TEMPO/obsys.dat
RUN echo '-2559454.08    5095372.14      -2849057.18       MWA                 mwa' >> $TEMPO2/observatory/observatories.dat

ENTRYPOINT /bin/bash