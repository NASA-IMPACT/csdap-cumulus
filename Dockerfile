# syntax=docker/dockerfile:1.2

# See https://terraspace.cloud/docs/install/docker/versioning/
# See https://hub.docker.com/r/boltops/terraspace/tags?page=1&name=ubuntu
FROM boltops/terraspace:1.1.5-ubuntu

# Replace shell with bash so we can source files within this Dockerfile
SHELL [ "/bin/bash", "-o", "pipefail", "-c" ]

RUN : \
  && apt-get update -y \
  && apt-get install -y --no-install-recommends \
  # Ruby requires the following to build gem native extensions
  g++=4:9.3.0-1ubuntu2 \
  make=4.2.1-1.2 \
  # AWS CLI help system requires groff
  groff=1.22.4-4build1 \
  # AWS Support Tools Lambda FindEniMappings requires jq
  jq=1.6-1ubuntu0.20.04.1 \
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && :

# Install AWS Session Manager Plugin
RUN : \
  && curl --no-progress-meter "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "/tmp/session-manager-plugin.deb" \
  && dpkg -i /tmp/session-manager-plugin.deb \
  && rm -f /tmp/session-manager-plugin.deb \
  && :

# Install AWS Support Tools
RUN : \
  && git clone --depth 1 https://github.com/awslabs/aws-support-tools.git /usr/local/aws-support-tools \
  && ln -s /usr/local/aws-support-tools/Lambda/FindEniMappings/findEniAssociations /usr/local/bin/findEniAssociations \
  && :

WORKDIR /work

# By default, Terraspace times out after 1 hour (3600s) during Terraform
# operations.  Since Cumulus operations can take longer than that, this default
# value causes problems, such as abruptly terminating in-flight deployments,
# without releasing locks, wreaking havoc.  This sets the timeout to 4 hours.
# See https://community.boltops.com/t/terraspace-execution-timeout/846
ENV TS_BUFFER_TIMEOUT=14400

# Install all of the Terraspace Ruby dependencies listed in Gemfile.lock.  This
# is required because the /usr/local/bin/terraspace wrapper runs `bundle exec`
# in the presence of `config/app.rb`, which we have.
COPY Gemfile Gemfile.lock ./
RUN bundle install && bundle clean --force

# Use tfenv to install Terraform (version specified in `.terraform-version`)
# The version in .terraform-version should be the version recommended for use
# with Cumulus.
COPY .terraform-version ./
RUN tfenv install

# Install nvm, node (version specified in `.nvmrc`), npm, and yarn
ENV NVM_DIR=/usr/local/nvm
COPY .nvmrc ./
RUN : \
  && mkdir -p "${NVM_DIR}" \
  && curl --no-progress-meter -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash \
  # For nvm.sh, the --install option is required when .nvmrc is present,
  # otherwise it exits with status 3 (even though it appears to work), which
  # causes Docker image build failure.
  && source "${NVM_DIR}/nvm.sh" --install \
  && npm install -g yarn@1.22.17 \
  && :

# Include CUMULUS_PREFIX in bash prompt so it is easy to see which environment
# we're dealing with, in order to reduce the likelihood of accidentally making
# changes in the wrong environment.
# hadolint ignore=SC2016
RUN echo 'PS1="(${CUMULUS_PREFIX:-WARNING! CUMULUS_PREFIX is undefined!}):\w \$ "' >> ~/.bashrc
