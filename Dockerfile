FROM rocker/geospatial:3.6.3

ENV NB_USER rstudio
ENV NB_UID 1000
ENV VENV_DIR /srv/venv

# Set ENV for all programs...
ENV PATH ${VENV_DIR}/bin:$PATH
# And set ENV for R! It doesn't read from the environment...
RUN echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron
RUN echo "export PATH=${PATH}" >> ${HOME}/.profile

# The `rsession` binary that is called by nbrsessionproxy to start R doesn't seem to start
# without this being explicitly set
ENV LD_LIBRARY_PATH /usr/local/lib/R/lib

ENV HOME /home/${NB_USER}
WORKDIR ${HOME}

RUN apt-get update && \
    apt-get -y install python3-venv python3-dev && \
    apt-get purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a venv dir owned by unprivileged user & set up notebook in it
# This allows non-root to install python libraries if required
RUN mkdir -p ${VENV_DIR} && chown -R ${NB_USER} ${VENV_DIR}

USER ${NB_USER}
RUN python3 -m venv ${VENV_DIR} && \
    # Explicitly install a new enough version of pip
    pip3 install pip==9.0.1 && \
    pip3 install --no-cache-dir \
         jupyter-rsession-proxy

RUN R --quiet -e "devtools::install_github('IRkernel/IRkernel')" && \
    R --quiet -e "IRkernel::installspec(prefix='${VENV_DIR}')" && \
    R --quiet -e "install.packages('sp')" && \
    R --quiet -e "install.packages('raster')" && \
    R --quiet -e "install.packages('rgdal')" && \
    R --quiet -e "install.packages('ggplot2')" && \
    R --quiet -e "install.packages('agricolae')" && \
    R --quiet -e "install.packages('reshape2')" && \
    R --quiet -e "install.packages('devtools')" && \
    R --quiet -e "install.packages('lme4')" && \
    R --quiet -e "install.packages('plyr')" && \
    R --quiet -e "install.packages('DescTools')" && \
    R --quiet -e "install.packages('maptools')" && \
    R --quiet -e "install.packages('foreach')" && \
    R --quiet -e "install.packages('parallel')" && \
    R --quiet -e "install.packages('doParallel')" && \
    R --quiet -e "install.packages('BiocManager')" && \
    R --quiet -e "BiocManager::install('EBImage')" && \
    R --quiet -e "devtools::install_github('filipematias23/FIELDimageR', dependencies=FALSE)"
    
    ## Copies your repo files into the Docker Container
USER root
COPY . ${HOME}
## Enable this to copy files from the binder subdirectory
## to the home, overriding any existing files.
## Useful to create a setup on binder that is different from a
## clone of your repository
## COPY binder ${HOME}
RUN chown -R ${NB_USER} ${HOME}

## Become normal user again
USER ${NB_USER}

CMD jupyter notebook --ip 0.0.0.0
