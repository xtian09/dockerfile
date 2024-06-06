FROM ubuntu:20.04

ENV USERNAME="build"
ENV USERUID="1000"
ENV USERGID="1000"

COPY features/src/common-utils vendor/aosp.sh /tmp/common-utils/

RUN chmod +x /tmp/common-utils/aosp.sh && /tmp/common-utils/aosp.sh && rm -rf /tmp/common-utils

USER ${USERNAME}

WORKDIR /home/${USERNAME}/workspace