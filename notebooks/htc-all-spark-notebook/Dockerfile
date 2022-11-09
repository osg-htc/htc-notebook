########################
# Dockerfile to make image spawned by CHTC Jupyterhub that
# launches a personal HTCondor instance upon spawning a
# notebook.  Designed to be used with SystemUserSpawner in mind.
# Author: Todd Tannenbaum <tannenba@cs.wisc.edu>
#
# Copyright (C) HTCondor Team, Computer Sciences Dept, Univ of Wisconsin-Madison
# Distributed under terms of the Apache Licence, Version 2.0.

FROM jupyter/all-spark-notebook:ubuntu-20.04

# metadata
LABEL maintainer="chtc@cs.wisc.edu"

# select HTCondor release series (first two parts only!)
ARG HTCONDOR_VERSION=9.x

# default to jupyter lab
ENV JUPYTER_ENABLE_LAB=1

USER root

# add HTCondor config
COPY condor_config.local /etc/condor/condor_config.local

# add an entrypoint that starts HTCondor
COPY entrypoint.sh /.entrypoint.sh

# install HTCondor, and a few other convenience tools
# also fix permissions on the files copied above
RUN apt-get update -y \
 && apt-get upgrade -y \
 && apt-get install -y gnupg vim less git man \
 && wget -qO - https://research.cs.wisc.edu/htcondor/repo/keys/HTCondor-${HTCONDOR_VERSION}-Key | apt-key add - \
 && echo "deb  https://research.cs.wisc.edu/htcondor/repo/ubuntu/${HTCONDOR_VERSION} focal main" >> /etc/apt/sources.list \
 && apt-get update -y \
 && apt-get install -y htcondor \
 && apt-get clean -y \
 && rm -rf /var/lib/apt/lists/* \
 && chmod +x /.entrypoint.sh \
 && chown -R ${NB_UID}:${NB_GID} /home/${NB_USER}/.condor \
 && fix-permissions ${HOME}

USER $NB_UID:$NB_GID

# install HTCondor Python bindings, HTChirp, and HTMap
RUN pip install --no-cache-dir htcondor htchirp htmap

# set up environment variable hooks for HTMap settings
# todo: once HTMap can decide the delivery method itself, remove it from here!
# todo: embed image name so HTMap can use the same image for exec
ENV HTMAP_DELIVERY_METHOD="assume"

ENTRYPOINT ["tini", "-g", "--", "/.entrypoint.sh"]
CMD ["start-notebook.sh"]

########################
# Minimal JupyterLab with support for sssd and HTCondor.
#
# The intent is that /var/lib/sss/pipes will be shared with some other
# container that is running an sssd daemon. The notebook container should
# not include configuration for sssd.
#
# In order to accommodate the sharing of sssd's "pipes" directory, we
# create the sssd user and group with explicit IDs rather than allowing
# packages to select arbitrary IDs.

USER root

RUN groupadd -r -g 996 sssd \
    && useradd -r -g sssd -u 996 -d / -s /usr/sbin/nologin -c "System user for sssd" sssd \
    #
    && apt-get update \
    && apt-get install -y sssd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY etc /etc/
COPY opt /opt/

RUN chmod ug=r,o= /etc/sudoers.d/*

USER $NB_UID:$NB_GID

ENTRYPOINT ["tini", "-g", "--", "/opt/osg/bin/entrypoint.sh"]

########################
# Add support for OSG Connect.

USER root

RUN python3 -m pip install -U pip setuptools wheel \
    && python3 -m pip install -U git+https://github.com/brianaydemir/osgconnect-scripts.git@2to3

USER $NB_UID:$NB_GID

########################
# Add support for Apptainer.

USER root

RUN apt-get update \
    && apt-get install -y wget \
    && cd /tmp \
    && wget https://github.com/apptainer/apptainer/releases/download/v1.1.3/apptainer_1.1.3_amd64.deb \
    && apt-get install -y ./apptainer_1.1.3_amd64.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER $NB_UID:$NB_GID
