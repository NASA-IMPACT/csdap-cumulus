# syntax=docker/dockerfile:1.2

# See https://terraspace.cloud/docs/install/docker/versioning/
# See https://hub.docker.com/r/boltops/terraspace/tags?page=1&name=ubuntu
FROM boltops/terraspace:2.2.2-ubuntu

# Replace shell with bash so we can source files within this Dockerfile
SHELL [ "/bin/bash", "-o", "pipefail", "-c" ]

RUN : \
  && apt-get update -y \
  && apt-get install -y --no-install-recommends \
  bc=1.07.1-3build1 \
  # Ruby requires g++ following to build gem native extensions
  g++=4:11.2.0-1ubuntu1 \
  make=4.3-4.1build1 \
  # AWS CLI help system requires groff (not needed for CI)
  groff=1.22.4-8build1 \
  # AWS Support Tools Lambda FindEniMappings requires jq (not needed for CI)
  jq=1.6-2.1ubuntu3 \
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && :

# Install AWS Session Manager Plugin (not needed for CI)
RUN : \
  && curl --no-progress-meter "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "/tmp/session-manager-plugin.deb" \
  && dpkg -i /tmp/session-manager-plugin.deb \
  && rm -f /tmp/session-manager-plugin.deb \
  && :

# Install AWS Support Tools (not needed for CI)
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
ENV NODE_VERSIONS=$NVM_DIR/versions/node
ENV NODE_VERSION_PREFIX=v

COPY .nvmrc ./
# hadolint ignore=SC1091
RUN : \
  && mkdir -p "${NVM_DIR}" \
  && curl --no-progress-meter -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash \
  # For nvm.sh, the --install option is required when .nvmrc is present,
  # otherwise it exits with status 3 (even though it appears to work), which
  # causes Docker image build failure.
  && source "${NVM_DIR}/nvm.sh" --install \
  && npm install -g yarn@1.22.19 \
  && npm install -g hygen@6.2.11 \
  && :

# Install Cumulus CLI (see https://github.com/NASA-IMPACT/cumulus-cli)
WORKDIR /usr/src
RUN git clone --depth 1 https://github.com/NASA-IMPACT/cumulus-cli.git
WORKDIR /usr/src/cumulus-cli
# hadolint ignore=SC1091
RUN : \
  && source "${NVM_DIR}/nvm.sh" --install \
  && nvm install \
  && npm install \
  && npm run build \
  && npm install -g \
  && ln -s "$(which cumulus)" /usr/local/bin/cumulus \
  && :

WORKDIR /work

# Install node dependencies
COPY package.json yarn.lock ./
# hadolint ignore=SC1091
RUN : \
  # For nvm.sh, the --install option is required when .nvmrc is present,
  # otherwise it exits with status 3 (even though it appears to work), which
  # causes Docker image build failure.
  && source "${NVM_DIR}/nvm.sh" --install \
  && nvm install \
  && :

# Include TS_ENV in bash prompt so it is easy to see which environment
# we're dealing with, in order to reduce the likelihood of accidentally making
# changes in the wrong environment.
# hadolint ignore=SC2016
RUN : \
  && echo 'export PS1="(${AWS_PROFILE:-[ERROR: AWS_PROFILE is not defined]}:${TS_ENV:-[ERROR: TS_ENV is undefined]}):\w \$ "' >> ~/.bashrc \
  #-----------------------------------------------------------------------------
  # IMPORTANT
  #-----------------------------------------------------------------------------
  # The value that `CUMULUS_PREFIX` is set to is duplicated in the file
  # `config/terraform/tfvars/base.tfvars`.  If you change the value here, you
  # must also make the corresponding change there.
  && echo 'export CUMULUS_PREFIX="cumulus-${TS_ENV}"' >> ~/.bashrc \
  #-----------------------------------------------------------------------------
  && :
