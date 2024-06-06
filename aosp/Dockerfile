FROM ubuntu:latest

# since ubuntu 24 has a default uid 1000 user named ubuntu, we just use it
ENV USERNAME="ubuntu"

COPY features/src/common-utils aosp/aosp.sh /tmp/common-utils/

RUN chmod +x /tmp/common-utils/aosp.sh && /tmp/common-utils/aosp.sh && rm -rf /tmp/common-utils

USER ${USERNAME}

WORKDIR /home/${USERNAME}/workspace