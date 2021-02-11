## Use a tag instead of "latest" for reproducibility
FROM rocker/binder:latest

## Declares build arguments
ARG NB_USER
ARG NB_UID

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

