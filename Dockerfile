# Set the bage image
FROM rockylinux:8 AS os_base

# File Author / Maintainer
LABEL auther="Sean Elliott"
LABEL version=1.0

ARG DEBIAN_FRONTEND=noninteractive
COPY ./splunk_ulimits.conf /etc/security/limits.d/splunk_ulimits.conf

RUN dnf --nodocs -y upgrade-minimal \
    && dnf --nodocs -y install --setopt=install_weak_deps=False wget sudo ca-certificates \
    && dnf clean all \
    && chmod 0644 /etc/security/limits.d/splunk_ulimits.conf

FROM os_base as splunk_install

ENV SPLUNK_HOME=/opt/splunk \
    SPLUNK_GROUP=splunk \
    SPLUNK_USER=splunk \
    SPLUNK_TGZ=splunk-8.2.1-ddff1c41e5cf-Linux-x86_64.tgz \
    SPLUNK_URL="https://download.splunk.com/products/splunk/releases/8.2.1/linux/splunk-8.2.1-ddff1c41e5cf-Linux-x86_64.tgz"

# Download and Install Splunk
RUN wget -q -O ${SPLUNK_TGZ} ${SPLUNK_URL} \
  && tar xzvf ${SPLUNK_TGZ} -C /opt \
  && rm -f ${SPLUNK_TGZ} \
  && rm -rf ${SPLUNK_HOME}/splunk-8.2.1-ddff1c41e5cf-linux-2.6-x86_64-manifest \
  && rm -rf ${SPLUNK_HOME}/etc/apps/SplunkForwarder \
  && rm -rf ${SPLUNK_HOME}/etc/apps/SplunkLightForwarder \
  && rm -rf ${SPLUNK_HOME}/etc/apps/introspection_generator_addon \
  && rm -rf ${SPLUNK_HOME}/etc/apps/learned \
  && rm -rf ${SPLUNK_HOME}/etc/apps/legacy \
  && rm -rf ${SPLUNK_HOME}/etc/apps/python_upgrade_readiness_app \
  && rm -rf ${SPLUNK_HOME}/etc/apps/sample_app \
  && rm -rf ${SPLUNK_HOME}/etc/apps/splunk_archiver \
  && rm -rf ${SPLUNK_HOME}/etc/apps/splunk_essentials_8_2 \
  && rm -rf ${SPLUNK_HOME}/etc/apps/splunk_gdi \
  && rm -rf ${SPLUNK_HOME}/etc/apps/splunk_instrumentation \
  && rm -rf ${SPLUNK_HOME}/etc/apps/splunk_internal_metrics \
  && rm -rf ${SPLUNK_HOME}/etc/apps/splunk_metrics_workspace \
  && rm -rf ${SPLUNK_HOME}/etc/apps/splunk_monitoring_console \
  && rm -rf ${SPLUNK_HOME}/etc/apps/splunk_rapid_diag \
  && rm -rf ${SPLUNK_HOME}/etc/apps/splunk_secure_gateway \
  && rm -rf ${SPLUNK_HOME}/etc/apps/upgrade_readiness_app \
  && groupadd ${SPLUNK_GROUP} \
  && useradd ${SPLUNK_USER} -d ${SPLUNK_HOME} -g ${SPLUNK_GROUP} --shell /bin/bash \
  && chown -R ${SPLUNK_USER}:${SPLUNK_GROUP} ${SPLUNK_HOME} \
  && mkdir /home/root \
  && export HOME=/home/root

COPY --chown=splunk:splunk ./bashrc ${SPLUNK_HOME}/.bashrc
COPY --chown=splunk:splunk ./splunk.secret ${SPLUNK_HOME}/etc/auth/splunk.secret
COPY --chown=splunk:splunk user-seed.conf server.conf inputs.conf ${SPLUNK_HOME}/etc/system/local/

FROM splunk_install as splunk_base

# Required to accept the license before using splunk set commands
RUN ${SPLUNK_HOME}/bin/splunk enable boot-start -user ${SPLUNK_USER} -systemd-managed 0 --accept-license --answer-yes --no-prompt \
  && ${SPLUNK_HOME}/bin/splunk set servername splunk-docker-simple \
  && ${SPLUNK_HOME}/bin/splunk set default-hostname splunk-docker-simple \
  && ${SPLUNK_HOME}/bin/splunk set minfreemb 1024

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

#CMD [ "${SPLUNK_HOME}/bin/splunk start", "--nodaemon" ]
ENTRYPOINT [ "${SPLUNK_HOME}/bin/splunk start", "--nodaemon" ]
