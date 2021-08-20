# syntax=docker/dockerfile:1.2
FROM ubuntu

RUN apt-get update && apt-get install git unzip -y # so we can install tfenv
RUN apt-get update && apt-get install curl gnupg -y # so tfenv can install terraform

WORKDIR /tmp
COPY bin/install/terraform.sh bin/install/terraform.sh
RUN bin/install/terraform.sh

RUN echo "deb https://apt.boltops.com stable main" > /etc/apt/sources.list.d/boltops.list
RUN curl -s https://apt.boltops.com/boltops-key.public | apt-key add -
#RUN apt-get update
#RUN apt-get install terraspace -y

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install awscli -y

WORKDIR /root
ENV PATH="/root/.tfenv/bin:$PATH"

RUN apt-get update && apt-get install -y gcc make bsdmainutils && \
  curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb" && \
  dpkg -i session-manager-plugin.deb && \
  rm -f session-manager-plugin.deb

WORKDIR /work

COPY .terraform-version ./
RUN tfenv install

ENTRYPOINT ["/work/bin/env.sh"]
CMD ["/usr/bin/env", "bash"]
