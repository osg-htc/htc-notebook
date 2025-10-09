########################
# Install RStudio
#     (https://posit.co/download/rstudio-server/)
# and make it easy to access
#     (https://github.com/jupyterhub/jupyter-rsession-proxy).

ARG RSTUDIO_DEB=rstudio-server-2025.09.1-401-amd64.deb

USER root

RUN true \
    #
    # Upgrade R.
    #
    && mamba install -y 'r-base~=4.5.1' \
    #
    # Install only the RStudio package.
    # R itself is already installed into the Conda environment.
    #
    && apt-get update -y \
    && wget https://download2.rstudio.org/server/jammy/amd64/${RSTUDIO_DEB} \
    && apt-get install -y ./${RSTUDIO_DEB} \
    && rm -rf ${RSTUDIO_DEB} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    #
    # Configure 'rserver'.
    # Ensure that the Conda environment's shared libraries are preferred.
    #
    && mkdir -p /etc/rstudio \
    && printf 'rsession-which-r=%s\n' "$(command -v R)" >> /etc/rstudio/rserver.conf \
    && printf 'rsession-ld-library-path=%s\n' "/opt/conda/lib/R/lib:/opt/conda/lib" >> /etc/rstudio/rserver.conf \
    && true

USER $NB_UID:$NB_GID

RUN python3 -m pip install --no-cache-dir jupyter-rsession-proxy
