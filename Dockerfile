# Set the bage image
FROM ubuntu:19.04 AS os_base
 
# File Author / Maintainer
MAINTAINER Mason Morales <mason@splunk.com>
 
ARG DEBIAN_FRONTEND=noninteractive
 
RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime \
&& apt-get update \
&& apt-get install -y ntp \
&& service ntp restart \
&& apt-get install -y --no-install-recommends wget tar sudo openssl ca-certificates vim \
&& rm -rf /var/cache/apt/* \
&& rm -rf /var/lib/apt/lists/* \
&& apt clean autoclean
 
FROM os_base as splunk_install
 
ENV SPLUNK_HOME=/opt/splunk \
    SPLUNK_GROUP=splunk \
    SPLUNK_USER=splunk
 
# Download and Install Splunk
RUN wget -O splunk-7.2.6-c0bf0f679ce9-Linux-x86_64.tgz 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.2.6&product=splunk&filename=splunk-7.2.6-c0bf0f679ce9-Linux-x86_64.tgz&wget=true' \
  && tar xzvf splunk-7.2.6-c0bf0f679ce9-Linux-x86_64.tgz -C /opt \
  && rm -f /splunk-7.2.6-c0bf0f679ce9-Linux-x86_64.tgz \
  && groupadd ${SPLUNK_GROUP} && useradd ${SPLUNK_USER} -b /opt/ -g ${SPLUNK_GROUP} \
  && chown -R ${SPLUNK_USER}:${SPLUNK_GROUP} ${SPLUNK_HOME}
 
FROM splunk_install as splunk_base
COPY --chown=splunk:splunk ./bashrc ${SPLUNK_HOME}/.bashrc
COPY --chown=splunk:splunk ./user-seed.conf ${SPLUNK_HOME}/etc/system/local/user-seed.conf
COPY --chown=splunk:splunk ./server.conf ${SPLUNK_HOME}/etc/system/local/server.conf
COPY --chown=splunk:splunk ./inputs.conf ${SPLUNK_HOME}/etc/system/local/inputs.conf

RUN ${SPLUNK_HOME}/bin/splunk enable boot-start -user ${SPLUNK_USER} -systemd-managed 0 --accept-license --answer-yes --no-prompt

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
