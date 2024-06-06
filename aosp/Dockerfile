FROM ubuntu:24.04

COPY features/src/common-utils aosp/aosp.sh /tmp/common-utils/

RUN chmod +x /tmp/common-utils/aosp.sh
# since ubuntu 24 has a default uid 1000 user named ubuntu, we just use it
ENV USERNAME="ubuntu"

RUN /tmp/common-utils/aosp.sh

RUN rm -rf /tmp/common-utils

USER ${USERNAME}

WORKDIR /home/${USERNAME}/workspace