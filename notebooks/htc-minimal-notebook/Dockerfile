########################
# Dockerfile to make image spawned by CHTC Jupyterhub that
# launches a personal HTCondor instance upon spawning a
# notebook.  Designed to be used with SystemUserSpawner in mind.
# Author: Todd Tannenbaum <tannenba@cs.wisc.edu>
#
# Copyright (C) HTCondor Team, Computer Sciences Dept, Univ of Wisconsin-Madison
# Distributed under terms of the Apache Licence, Version 2.0.

FROM quay.io/jupyter/minimal-notebook:hub-5.2.1
LABEL maintainer="chtc@cs.wisc.edu"
USER root


## Default to JupyterLab.
ENV JUPYTER_ENABLE_LAB=1


## Add `sudo` configuration for running commands as `jovyan`.
COPY 90-run-as-jovyan /etc/sudoers.d/
RUN chmod 400 /etc/sudoers.d/*


## Install HTCondor and other tools.
RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y curl git gnupg less man openjdk-21-jdk vim wget \
    #
    # Install HTCondor.
    #
    && curl -fsSL https://research.cs.wisc.edu/htcondor/repo/keys/HTCondor-24.x-Key | apt-key add - \
    && echo "deb http://research.cs.wisc.edu/htcondor/repo/ubuntu/24.x noble main" > /etc/apt/sources.list.d/htcondor.list \
    && apt-get update -y \
    && apt-get install -y minihtcondor pelican pelican-osdf-compat \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    #
    # Fix the minicondor config.
    #
    && echo 'CONDOR_HOST = $(IP_ADDRESS)' > /etc/condor/config.d/00-fix-minicondor \
    #
    # Fix permissions on various files and directories.
    #
    && mkdir -p /home/${NB_USER}/.condor \
    && chown -R ${NB_UID}:${NB_GID} /home/${NB_USER}/.condor \
    && fix-permissions ${HOME} \
    #
    # Create a directory for "additional runtime customizations."
    #
    && mkdir /image-init.d/ \
    #
    # Make other customizations for OSG and the OSPool.
    #
    && sed -i -e 's/@\\h//' /etc/bash.bashrc /home/jovyan/.bashrc \
    && true
COPY condor_config.local /etc/condor/condor_config.local
ENV HTMAP_DELIVERY_METHOD="assume"


## Add an entrypoint that starts HTCondor.
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["tini", "-g", "--", "/entrypoint.sh"]
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

RUN mkdir -p /usr/libexec \
    && ln -s /usr/lib/condor/libexec /usr/libexec/condor


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

RUN groupadd -r -g 990 sssd \
    && useradd -r -g sssd -u 990 -d / -s /usr/sbin/nologin -c "System user for sssd" sssd \
    #
    && apt-get update \
    && apt-get install -y sssd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


########################
# Add support for Apptainer.

ARG APPTAINER_VERSION=1.3.6
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
    #
    && rm -rf /etc/subuid /etc/subgid \
    #
    # Do not allow users to utilize the setuid program flow within Apptainer.
    #
    && sed -i \
          -e 's/^allow setuid.*$/allow setuid = no/' \
          /etc/apptainer/apptainer.conf


########################
# Make other assorted updates to the Jupyter Python environment.

USER $NB_UID:$NB_GID

RUN true \
    # Allow notebooks to use kernels in Conda environments.
    && conda install nb_conda_kernels \
    # Install HTCondor, and additional kernels and plugins.
    && (cd /tmp \
        && curl -fsSL -O https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip \
        && unzip ijava-1.3.0.zip \
        && python3 install.py --sys-prefix \
        && rm -rf /tmp/ijava-1.3.0.zip /tmp/install.py /tmp/java) \
    && python3 -m pip install -U --no-cache-dir \
          bash_kernel \
          htchirp \
          htcondor \
          htmap \
          jupyter_resource_usage \
          jupyterlab_git \
          git+https://github.com/brianaydemir/osgconnect-scripts.git@2to3 \
          git+https://github.com/PelicanPlatform/pelicanfs.git@84550e384ea28b3066bb9997d3e59517029cd2a2 \
    && python3 -m bash_kernel.install --sys-prefix \
    && jupyter labextension disable "@jupyterlab/apputils-extension:announcements" \
    && true
