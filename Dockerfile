# Set the bage image
FROM ubuntu:19.04 AS os_base

# File Author / Maintainer
MAINTAINER Mason Morales <mason@splunk.com>

ARG DEBIAN_FRONTEND=noninteractive

COPY ./splunk_ulimits.conf /etc/security/limits.d/splunk_ulimits.conf

RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime \
  && apt-get update \
  && apt-get install -y ntp \
  && service ntp restart \
  && apt-get install -y --no-install-recommends wget tar sudo openssl ca-certificates vim \
  && rm -rf /var/cache/apt/* \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean autoclean \
  && chmod 0644 /etc/security/limits.d/splunk_ulimits.conf

FROM os_base as splunk_install

ENV SPLUNK_HOME=/opt/splunk \
    SPLUNK_GROUP=splunk \
    SPLUNK_USER=splunk \
    SPLUNK_TGZ=splunk-8.2.1-ddff1c41e5cf-Linux-x86_64.tgz \
    SPLUNK_URL='https://download.splunk.com/products/splunk/releases/8.2.1/linux/splunk-8.2.1-ddff1c41e5cf-Linux-x86_64.tgz'

# Download and Install Splunk
RUN wget -O ${SPLUNK_TGZ} ${SPLUNK_URL} \
  && tar xzvf ${SPLUNK_TGZ} -C /opt \
  && rm -f ${SPLUNK_TGZ} \
  && rm -rf  ${SPLUNK_GROUP}/splunk-8.2.1-ddff1c41e5cf-linux-2.6-x86_64-manifest \
  && groupadd ${SPLUNK_GROUP} \
  && useradd ${SPLUNK_USER} -d ${SPLUNK_HOME} -g ${SPLUNK_GROUP} --shell /bin/bash \
  && chown -R ${SPLUNK_USER}:${SPLUNK_GROUP} ${SPLUNK_HOME} \
  && mkdir /home/root \
  && export HOME=/home/root

FROM splunk_install as splunk_base
COPY --chown=splunk:splunk ./bashrc ${SPLUNK_HOME}/.bashrc
COPY --chown=splunk:splunk ./splunk.secret ${SPLUNK_HOME}/etc/auth/splunk.secret
COPY --chown=splunk:splunk ./user-seed.conf ${SPLUNK_HOME}/etc/system/local/user-seed.conf
COPY --chown=splunk:splunk ./server.conf ${SPLUNK_HOME}/etc/system/local/server.conf
COPY --chown=splunk:splunk ./inputs.conf ${SPLUNK_HOME}/etc/system/local/inputs.conf

# Required to accept the license before using splunk set commands
RUN ${SPLUNK_HOME}/bin/splunk enable boot-start -user ${SPLUNK_USER} -systemd-managed 0 --accept-license --answer-yes --no-prompt
RUN ${SPLUNK_HOME}/bin/splunk set servername splunk-docker-simple
RUN ${SPLUNK_HOME}/bin/splunk set default-hostname splunk-docker-simple
RUN ${SPLUNK_HOME}/bin/splunk set minfreemb 1024

USER ${SPLUNK_USER}
WORKDIR ${SPLUNK_HOME}

VOLUME [ "${SPLUNK_HOME}/etc", "${SPLUNK_HOME}/var" ]

# Splunk Web
EXPOSE 8000
# Splunk2Splunk (Data)
EXPOSE 9997
# KV Store
EXPOSE 8191
# HTTP Event Collector (HEC)
EXPOSE 8088

ENTRYPOINT ${SPLUNK_HOME}/bin/splunk start --nodaemon

