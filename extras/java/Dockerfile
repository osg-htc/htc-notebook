########################
# Install Java

USER root

RUN true \
    #
    # Install OpenJDK.
    #
    && apt-get update -y \
    && apt-get install -y openjdk-21-jdk \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    #
    # Install IJava.
    #
    && (cd /tmp \
        && curl -fsSL -O https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip \
        && unzip ijava-1.3.0.zip \
        && python3 install.py --sys-prefix \
        && rm -rf /tmp/ijava-1.3.0.zip /tmp/install.py /tmp/java) \
    && true

USER $NB_UID:$NB_GID
