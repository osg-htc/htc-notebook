########################
# Dockerfile to make image spawned by CHTC Jupyterhub that
# launches a personal HTCondor instance upon spawning a
# notebook.  Designed to be used with SystemUserSpawner in mind.
# Author: Todd Tannenbaum <tannenba@cs.wisc.edu>
#
# Copyright (C) HTCondor Team, Computer Sciences Dept, Univ of Wisconsin-Madison
# Distributed under terms of the Apache Licence, Version 2.0.

FROM jupyter/scipy-notebook:hub-4.0.2

# metadata
LABEL maintainer="chtc@cs.wisc.edu"

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
 && apt-get install -y curl git gnupg less man vim wget \
 && apt-get clean -y \
 && rm -rf /var/lib/apt/lists/* \
 #
 # Install HTCondor.
 #
 && curl -fsSL https://research.cs.wisc.edu/htcondor/repo/keys/HTCondor-10.x-Key | apt-key add - \
 && echo "deb [arch=amd64] http://research.cs.wisc.edu/htcondor/repo/ubuntu/10.x jammy main" > /etc/apt/sources.list.d/htcondor.list \
 && apt-get update -y \
 && apt-get install -y minihtcondor \
 #
 # Fix permissions on various files and directories.
 #
 && chmod +x /.entrypoint.sh \
 && chown -R ${NB_UID}:${NB_GID} /home/${NB_USER}/.condor \
 && fix-permissions ${HOME} \
 #
 # Create the directory for "additional runtime customizations".
 #
 && mkdir /image-init.d/

# add sudo config for running commands as jovyan
# (in case the container is being run as some other user)
COPY 90-run-as-jovyan /etc/sudoers.d/
RUN chmod ug=r,o= /etc/sudoers.d/*

USER $NB_UID:$NB_GID

# install HTCondor Python bindings, HTChirp, and HTMap
RUN pip install --no-cache-dir \
      htchirp \
      htcondor \
      htmap

# set up environment variable hooks for HTMap settings
# todo: once HTMap can decide the delivery method itself, remove it from here!
# todo: embed image name so HTMap can use the same image for exec
ENV HTMAP_DELIVERY_METHOD="assume"

ENTRYPOINT ["tini", "-g", "--", "/.entrypoint.sh"]
CMD ["start-notebook.sh"]

########################
# Add support for integrating with non-Ubuntu environments.
#
# In order to simulate in Jupyter the experience of running directly on an
# access point, we need to take into account the fact that the access point
# might be running on an EL-based distribution and not Ubuntu.
#
# For example, in order to use executables in $(LIBEXEC), Jupyter and the AP
# must agree on its location. We create the symlink for this here, but leave
# it to the running container to configure HTCondor to actually use it.

USER root

RUN mkdir -p /usr/libexec \
    && ln -s /usr/lib/condor/libexec /usr/libexec/condor

USER $NB_UID:$NB_GID

########################
# Add support for sssd.
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

USER $NB_UID:$NB_GID

########################
# Add support for OSDF.

USER root

ARG OSDF_CLIENT_VERSION=6.9.4
ARG OSDF_CLIENT_TGZ=osdf-client_${OSDF_CLIENT_VERSION}_Linux_x86_64.tar.gz

RUN cd /tmp \
    && wget https://github.com/htcondor/osdf-client/releases/download/v${OSDF_CLIENT_VERSION}/${OSDF_CLIENT_TGZ} \
    && tar zxvf ${OSDF_CLIENT_TGZ} \
          osdf_config_mgr \
          stashcp \
          stash_plugin \
    && mv \
          osdf_config_mgr \
          stashcp \
          stash_plugin \
          /usr/bin/ \
    && ln -s stashcp /usr/bin/osdf_cp \
    && rm -rf ${OSDF_CLIENT_TGZ}

USER $NB_UID:$NB_GID

########################
# Add support for OSG Connect.

RUN python3 -m pip install -U --no-cache-dir git+https://github.com/brianaydemir/osgconnect-scripts.git@2to3

########################
# Add support for Apptainer.

USER root

ARG APPTAINER_VERSION=1.2.3
ARG APPTAINER_DEB=apptainer_${APPTAINER_VERSION}_amd64.deb

RUN cd /tmp \
    && wget https://github.com/apptainer/apptainer/releases/download/v${APPTAINER_VERSION}/${APPTAINER_DEB} \
    #
    && apt-get update \
    && apt-get install -y ./${APPTAINER_DEB} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* ./${APPTAINER_DEB} \
    #
    # Signal to Apptainer that it is running in an unprivileged container.
    # Reference: https://apptainer.org/docs/user/main/fakeroot.html.
    && rm -rf /etc/subuid /etc/subgid \
    # Do not allow users to utilize the setuid program flow within Apptainer.
    # Do not automatically bind mount /proc within the container.
    && sed -i \
          -e 's/^allow setuid.*$/allow setuid = no/' \
          -e 's/^mount proc.*$/mount proc = no/' \
          /etc/apptainer/apptainer.conf

USER $NB_UID:$NB_GID

########################
# Add support to Jupyter for a bash kernel.

RUN python3 -m pip install -U --no-cache-dir bash_kernel \
    && python3 -m bash_kernel.install --sys-prefix

########################
# Other customizations for OSG.

USER root

RUN sed -i -e 's/@\\h//' /etc/bash.bashrc /home/jovyan/.bashrc

USER $NB_UID:$NB_GID
