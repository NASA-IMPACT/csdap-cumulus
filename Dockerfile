# syntax=docker/dockerfile:1.2
FROM boltops/terraspace

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Remove AWS CLI v1 and install v2
RUN : \
  && apt-get remove -y awscli \
  && apt-get autoremove -y \
  && curl --no-progress-meter "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" \
  && unzip -q /tmp/awscliv2.zip -d /tmp \
  && /tmp/aws/install --bin-dir /usr/bin \
  && rm -rf /tmp/awscliv2.zip /tmp/aws/ \
  && aws --version \
  && :

# Install AWS Session Manager Plugin
RUN : \
  && curl --no-progress-meter "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "/tmp/session-manager-plugin.deb" \
  && dpkg -i /tmp/session-manager-plugin.deb \
  && rm -f /tmp/session-manager-plugin.deb \
  && :

# Install Ruby, Terraspace, and Docker CLI dependencies
RUN : \
  && apt-get update --fix-missing \
  && apt-get install -y \
  bsdmainutils \
  g++ \
  gcc \
  graphviz \
  lsb-release \
  make \
  rsync \
  && apt-get autoremove -y \
  && :

# Install Docker CLI
RUN : \
  && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
  && apt-get update -y \
  && apt-get install -y docker-ce-cli \
  && :

WORKDIR /work
ENV NVM_DIR=/usr/local/nvm
COPY .nvmrc ./

# Install nvm, node/npm, and yarn

# NOTE
#   For nvm.sh, the --install option is required when .nvmrc is present, otherwise it
#   exits with status 3 (even though it appears to work), which causes build failure.
RUN : \
  && mkdir -p "${NVM_DIR}" \
  && curl --no-progress-meter -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash \
  && source "${NVM_DIR}/nvm.sh" --install \
  && npm install -g yarn \
  && :

# Use tfenv to install Terraform (using version specified in .terraform-version)
COPY .terraform-version ./
RUN tfenv install

# Install all of the Terraspace Ruby dependencies listed in Gemfile.lock
COPY Gemfile Gemfile.lock ./
RUN bundle install && bundle clean --force
