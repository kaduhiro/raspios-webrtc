ARG VERSION=22.04

FROM ubuntu:${VERSION}
LABEL maintainer="kaduhiro <github@kaduhiro.com>"

RUN apt-get update \
    && apt-get upgrade -y

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      tzdata ca-certificates curl tini make
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      libx11-6 libxext6 libxtst6 \
      usbutils alsa-utils v4l-utils

RUN mkdir /app
WORKDIR /app

RUN apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/bin/tini", "--"]
