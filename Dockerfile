# syntax=docker/dockerfile:1.2
FROM boltops/terraspace:ubuntu

# Replace shell with bash so we can source files
SHELL [ "/bin/bash", "-o", "pipefail", "-c" ]

# Remove AWS CLI v1 and install v2
RUN : \
  && apt-get update -y \
  && apt-get remove -y awscli \
  # AWS CLI help system uses groff
  && apt-get install -y --no-install-recommends groff=1.22.4-4build1 \
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
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
  && apt-get install -y --no-install-recommends \
  bsdmainutils=11.1.2ubuntu3 \
  g++=4:9.3.0-1ubuntu2 \
  gcc=4:9.3.0-1ubuntu2 \
  graphviz=2.42.2-3build2 \
  lsb-release=11.1.0ubuntu2 \
  make=4.2.1-1.2 \
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && :

# Install Docker CLI and hadolint
RUN : \
  && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
  && apt-get update -y \
  && apt-get install -y --no-install-recommends docker-ce-cli=5:20.10.11~3-0~ubuntu-focal \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
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
  && npm install -g yarn@1.22.17 \
  && :

# Use tfenv to install Terraform (using version specified in .terraform-version)
COPY .terraform-version ./
RUN tfenv install

# Install all of the Terraspace Ruby dependencies listed in Gemfile.lock
COPY Gemfile Gemfile.lock ./
RUN bundle install && bundle clean --force
