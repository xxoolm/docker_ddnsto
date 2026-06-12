# Dockerfile for DDNSTO based alpine
# Copyright (C) 2020 - 2020 Janson <janson@linkease.com>
# Reference URL:
# https://www.ddnsto.com/

FROM alpine:latest
LABEL maintainer="Janson <janson@linkease.com>"

COPY install-ddnsto.sh /root/install-ddnsto.sh
COPY ddnsto-monitor.sh /usr/bin/ddnsto-monitor.sh
COPY ddnsto-support.sh /usr/bin/ddnsto-support.sh
COPY dist /dist
RUN set -ex \
	&& apk add --no-cache curl zip \
	&& chmod +x /root/install-ddnsto.sh \
	&& /root/install-ddnsto.sh

RUN chmod +x /usr/bin/ddnsto-monitor.sh /usr/bin/ddnsto-support.sh /usr/bin/ddnsto

ENV TZ=Asia/Shanghai
ENV TOKEN=
ENV DEVICE_NAME=
ENV DEVICE_IDX=
ENV LOG_LEVEL=2
ENV DDNSTO_SUPPORT_DIR=/ddnsto-support
ENV DDNSTO_AUTO_SUPPORT=1
ENV DDNSTO_AUTO_SUPPORT_INTERVAL=21600
ENV DDNSTO_SUPPORT_KEEP=5

CMD [ "/usr/bin/ddnsto-monitor.sh"]
