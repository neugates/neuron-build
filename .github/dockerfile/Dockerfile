FROM ubuntu:20.04

USER root

ENV TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive

RUN apt update \
    && apt install -y tzdata \
    && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

#alpine
#RUN apk add tzdata && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    #&& echo ${TZ} > /etc/timezone

RUN apt-get -y update && apt-get -y install \
	sudo pkg-config git cmake

COPY ./cross-install.sh /library/
RUN /library/cross-install.sh
