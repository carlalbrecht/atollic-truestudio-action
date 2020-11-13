FROM ubuntu:20.04

LABEL org.opencontainers.image.source https://github.com/carlalbrecht/atollic-truestudio-action

SHELL ["/bin/bash", "-c"]

ENV TRUESTUDIO_LOCATION /opt/atollic_truestudio

ENV TRUESTUDIO_PLATFORM linux_x86_64
ENV TRUESTUDIO_VERSION  9.3.0
ENV TRUESTUDIO_DATECODE 20190212-0734

ENV TRUESTUDIO_NAME Atollic_TrueSTUDIO_for_STM32_${TRUESTUDIO_PLATFORM}_v${TRUESTUDIO_VERSION}_${TRUESTUDIO_DATECODE}

ENV TRUESTUDIO_URL http://download.atollic.com/TrueSTUDIO/installers/${TRUESTUDIO_NAME}.tar.gz
ENV TRUESTUDIO_CHECKSUM_URL ${TRUESTUDIO_URL}.MD5

# Install dependencies
# HACK: We add bionic (18.04) repos here so that the installer script can
# install libwebkitgtk
RUN set -euxo pipefail \
 && echo "deb http://archive.ubuntu.com/ubuntu bionic main universe" >> /etc/apt/sources.list \
 && apt-get update \ 
 && apt-get install -y \
        curl \
        xvfb

# Download and verify TrueSTUDIO
RUN set -euxo pipefail \
 && curl -O ${TRUESTUDIO_URL} -O ${TRUESTUDIO_CHECKSUM_URL} \
 && md5sum -c $(basename ${TRUESTUDIO_CHECKSUM_URL}) \
 && rm $(basename ${TRUESTUDIO_CHECKSUM_URL})

# Install TrueSTUDIO
# This is performed using the interactive installer with piped input as follows:
#  * Accept EULA: Yes
#  * Do you want to install to ...: Change [to ${TRUESTUDIO_LOCATION}]
#  * Do you want to install to ${TRUESTUDIO_LOCATION}: Yes
#  * Install ST-Link udev rules: No
#  * Install SEGGER J-Link udev rules: No
#  * Remove temporary installation files: Yes
RUN set -euxo pipefail \
 && tar xzvfp ${TRUESTUDIO_NAME}.tar.gz \
 && rm ${TRUESTUDIO_NAME}.tar.gz \
 && truncate -s0 /tmp/preseed.cfg; \
    echo "tzdata tzdata/Areas select Etc" >> /tmp/preseed.cfg; \
    echo "tzdata tzdata/Zones/Etc select UTC" >> /tmp/preseed.cfg \
 && debconf-set-selections /tmp/preseed.cfg \
 && rm -f /etc/timezone /etc/localtime \
 && DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true \
    bash -c "(printf '1\n3\n${TRUESTUDIO_LOCATION}\n1\n2\n2\n1\n' && cat) \
           | ./Atollic_TrueSTUDIO_for_STM32_${TRUESTUDIO_VERSION}_installer/install.sh"

# Add tools to path
ENV PATH="${TRUESTUDIO_LOCATION}/ARMTools/bin:${TRUESTUDIO_LOCATION}/PCTools/bin:$PATH"

# Create `headless.sh` redirect script, which runs the real `headless.sh` from
# the IDE install directory
#
# We use `xvfb-run` to run the real `headless.sh`, to work around
# https://bugs.eclipse.org/bugs/show_bug.cgi?id=472042, preventing the console
# from being spammed with a bunch of non-fatal GTK errors
RUN set -euxo pipefail \
 && ln -s ${TRUESTUDIO_LOCATION}/ide/TrueSTUDIO /usr/bin \
 && printf '#!/bin/sh\ncd ${TRUESTUDIO_LOCATION}/ide\nxvfb-run ./headless.sh "$@"\n' > /usr/bin/headless.sh \
 && chmod a+x /usr/bin/headless.sh

# Copy in GitHub Actions adaptor entrypoint
COPY entrypoint.sh /entrypoint.sh

# Clean-up
RUN set -euxo pipefail \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

