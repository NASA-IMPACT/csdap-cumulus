# syntax=docker/dockerfile:1.2
FROM boltops/terraspace

# Remove AWS CLI v1 and install v2
RUN apt-get remove -y awscli \
  && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" \
  && unzip /tmp/awscliv2.zip -d /tmp \
  && /tmp/aws/install --bin-dir /usr/bin \
  && rm -rf /tmp/awscliv2.zip /tmp/aws/

RUN apt-get update && apt-get install -y \
  bsdmainutils \
  g++ \
  gcc \
  graphviz \
  make \
  && curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb" \
  && dpkg -i session-manager-plugin.deb \
  && rm -f session-manager-plugin.deb

WORKDIR /work

COPY .terraform-version Gemfile Gemfile.lock ./
RUN bundle install
RUN tfenv install
