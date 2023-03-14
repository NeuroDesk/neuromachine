# FROM jupyter/base-notebook:2023-02-28
FROM jupyter/base-notebook:python-3.10.9
# FROM jupyter/base-notebook:notebook-6.5.3

# Parent image source
# https://github.com/jupyter/docker-stacks/blob/86d42cadf4695b8e6fc3b3ead58e1f71067b765b/docker-stacks-foundation/Dockerfile
# https://github.com/jupyter/docker-stacks/blob/86d42cadf4695b8e6fc3b3ead58e1f71067b765b/base-notebook/Dockerfile

USER root

# Install base image dependancies
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        make \
        dirmngr \ 
        gcc \
        g++ \
        gpg-agent \
        libpng-dev \
        libjpeg-turbo8-dev \
        libcairo2-dev \
        libtool-bin \
        libossp-uuid-dev \
        libwebp-dev \
        lxde \
        libssl-dev \
        libvncserver-dev \
        libxt6 \
        xauth \
        xorg \
        freerdp2-dev \
        xrdp \
        xauth \
        xorg \
        xorgxrdp \
        tigervnc-standalone-server \
        tigervnc-common \
        lxterminal \
        lxrandr \
        curl \
        gpg \
        software-properties-common \
        dbus-x11 \
        man-db \
        pciutils \
        openjdk-19-jre \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /home/jovyan/.cache

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        build-essential \
        libseccomp-dev \
        libglib2.0-dev \
        pkg-config \
        squashfs-tools \
        cryptsetup \
        runc

# openjdk-11-jre \
# openssh-server \
# libpango1.0-dev \
# libssh2-1-dev \
# openssh-server \

ARG GO_VERSION="1.20.2"
ARG SINGULARITY_VERSION="3.11.0"
ARG TOMCAT_REL="9"
ARG TOMCAT_VERSION="9.0.73"
ARG GUACAMOLE_VERSION="1.5.0"
ARG JULIA_VERSION="1.8.3"

ENV LANG ""
ENV LANGUAGE ""
ENV LC_ALL ""

# Install singularity
RUN export VERSION=${GO_VERSION} OS=linux ARCH=amd64 \
    && wget https://go.dev/dl/go${VERSION}.${OS}-${ARCH}.tar.gz \
    && sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz \
    && rm go$VERSION.$OS-$ARCH.tar.gz \
    && export GOPATH=/opt/go \
    && export PATH=/usr/local/go/bin:${PATH}:${GOPATH}/bin \
    && mkdir -p $GOPATH/src/github.com/sylabs \
    && cd $GOPATH/src/github.com/sylabs \
    && wget https://github.com/sylabs/singularity/releases/download/v${SINGULARITY_VERSION}/singularity-ce-${SINGULARITY_VERSION}.tar.gz \
    && tar -xzvf singularity-ce-${SINGULARITY_VERSION}.tar.gz \
    && cd singularity-ce-${SINGULARITY_VERSION} \
    && ./mconfig --without-suid --prefix=/usr/local/singularity \
    && make -C builddir \
    && make -C builddir install \
    && rm -rf singularity-ce-${SINGULARITY_VERSION} \
    && rm -rf /usr/local/go $GOPATH \
    && ln -s /usr/local/singularity/bin/singularity /bin/ \ 
    && rm -rf /root/.cache

# Install Apache Tomcat
RUN wget -q https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_REL}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz -P /tmp \
    && tar -xf /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /tmp \
    && rm -rf /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz \
    && mv /tmp/apache-tomcat-${TOMCAT_VERSION} /usr/local/tomcat \
    && mv /usr/local/tomcat/webapps /usr/local/tomcat/webapps.dist \
    && mkdir /usr/local/tomcat/webapps \
    && chmod +x /usr/local/tomcat/bin/*.sh

# Install Apache Guacamole
WORKDIR /etc/guacamole
RUN wget -q "https://dlcdn.apache.org/guacamole/${GUACAMOLE_VERSION}/binary/guacamole-${GUACAMOLE_VERSION}.war" -O /usr/local/tomcat/webapps/ROOT.war \
    && wget -q "https://dlcdn.apache.org/guacamole/${GUACAMOLE_VERSION}/source/guacamole-server-${GUACAMOLE_VERSION}.tar.gz" -O /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}.tar.gz \
    && tar xvf /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}.tar.gz \
    && rm -rf /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}.tar.gz \
    && cd /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION} \
    && ./configure --with-init-dir=/etc/init.d \
    && make \
    && make install \
    && ldconfig \
    && rm -r /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}*

# Create Guacamole configurations (user-mapping.xml gets filled in the startup.sh script)
RUN echo -e "user-mapping: /etc/guacamole/user-mapping.xml\nguacd-hostname: 127.0.0.1" > /etc/guacamole/guacamole.properties
RUN echo -e "[server]\nbind_host = 127.0.0.1\nbind_port = 4822" > /etc/guacamole/guacd.conf

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        git \
        tigervnc-tools \
        lmod

# Install jupyter-server-proxy and disable announcements
RUN rm -rf /home/jovyan/.cache \
    && su jovyan -c "/opt/conda/bin/pip install jupyter-server-proxy" \
    && su jovyan -c "/opt/conda/bin/jupyter labextension disable @jupyterlab/apputils-extension:announcements"

# # Install plugins and pip packages
# RUN su jovyan -c "/opt/conda/bin/pip install jupyter-server-proxy" \
#     su jovyan -c "/opt/conda/bin/jupyter labextension disable @jupyterlab/apputils-extension:announcements" \
#     && rm -rf /home/jovyan/.cache

# Customise logo, wallpaper, terminal, panel
COPY config/neurodesk_brain_logo.svg /opt/neurodesk_brain_logo.svg
COPY config/background.png /usr/share/lxde/wallpapers/desktop_wallpaper.png
COPY config/pcmanfm.conf /etc/xdg/pcmanfm/LXDE/pcmanfm.conf
COPY config/lxterminal.conf /usr/share/lxterminal/lxterminal.conf
COPY config/panel /home/jovyan/.config/lxpanel/LXDE/panels/panel

# Add startup and config files for neurodesktop, jupyter, guacamole, vnc
RUN mkdir /home/jovyan/.vnc \
    && chown jovyan /home/jovyan/.vnc \
    && /usr/bin/printf '%s\n%s\n%s\n' 'password' 'password' 'n' | su jovyan -c vncpasswd
COPY --chown=jovyan:users config/xstartup /home/jovyan/.vnc
COPY --chown=jovyan:users config/startup.sh /opt/neurodesktop/startup.sh
COPY --chown=jovyan:users config/jupyter_notebook_config.py /home/jovyan/.jupyter/jupyter_notebook_config.py
COPY --chown=jovyan:root config/user-mapping.xml /etc/guacamole/user-mapping.xml
RUN chmod +x /opt/neurodesktop/startup.sh \
    /home/jovyan/.jupyter/jupyter_notebook_config.py \
    /home/jovyan/.vnc/xstartup
    
# Add notebook startup scripts
# https://jupyter-docker-stacks.readthedocs.io/en/latest/using/common.html
RUN mkdir -p /usr/local/bin/start-notebook.d/ \
    && mkdir -p /usr/local/bin/before-notebook.d/
COPY config/before-start.sh /usr/local/bin/start-notebook.d/
COPY config/after-start.sh /usr/local/bin/before-notebook.d/

COPY config/module.sh /usr/share/
COPY config/.bashrc /home/jovyan/tmp_bashrc
RUN cat /home/jovyan/tmp_bashrc >> /home/jovyan/.bashrc && rm /home/jovyan/tmp_bashrc

RUN rm -rf /home/jovyan/.cache \
    && su jovyan -c "/opt/conda/bin/pip install jupyterlmod"

# Create link to persistent storage on Desktop (This needs to happen before the users gets created!)
RUN mkdir -p /home/jovyan/neurodesktop-storage/containers \
    && mkdir -p /home/jovyan/Desktop/ /data \
    && chown -R jovyan:users /home/jovyan/Desktop/ \
    && chown -R jovyan:users /home/jovyan/neurodesktop-storage/ \
    && ln -s /home/jovyan/neurodesktop-storage/ /neurodesktop-storage

ENV SINGULARITY_BINDPATH /data
ENV LMOD_CMD /usr/share/lmod/lmod/libexec/lmod

# Install neurocommand
ADD "http://api.github.com/repos/NeuroDesk/neurocommand/commits/main" /tmp/skipcache
RUN rm /tmp/skipcache \
    && git clone https://github.com/NeuroDesk/neurocommand.git /neurocommand \
    && cd /neurocommand \
    && bash build.sh --lxde --edit \
    && bash install.sh \
    && ln -s /neurodesktop-storage/containers /neurocommand/local/containers

WORKDIR /home/jovyan

