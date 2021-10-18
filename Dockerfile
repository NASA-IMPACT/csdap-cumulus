# syntax=docker/dockerfile:1.2
FROM boltops/terraspace

# Remove AWS CLI v1 and install v2
RUN apt-get remove -y awscli \
  && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" \
  && unzip /tmp/awscliv2.zip -d /tmp \
  && /tmp/aws/install --bin-dir /usr/bin \
  && rm -rf /tmp/awscliv2.zip /tmp/aws/

# Install AWS Session Manager Plugin
RUN curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "/tmp/session-manager-plugin.deb" \
  && dpkg -i /tmp/session-manager-plugin.deb \
  && rm -f /tmp/session-manager-plugin.deb

# Install various Ruby and Terraspace dependencies
RUN apt-get update && apt-get install -y \
  bsdmainutils \
  g++ \
  gcc \
  graphviz \
  make

WORKDIR /work
COPY .terraform-version Gemfile Gemfile.lock ./

# Use tfenv to install Terraform (using version specified in .terraform-version)
RUN tfenv install

# Install all of the Terraspace Ruby dependencies listed in Gemfile.lock
RUN bundle install && bundle clean --force
