# syntax=docker/dockerfile:1.2
FROM boltops/terraspace

RUN apt-get update && apt-get install -y \
  bsdmainutils \
  gcc \
  graphviz \
  make \
  && \
  curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb" && \
  dpkg -i session-manager-plugin.deb && \
  rm -f session-manager-plugin.deb

WORKDIR /work

COPY .terraform-version Gemfile Gemfile.lock ./
RUN bundle install
RUN tfenv install

ENTRYPOINT ["/work/bin/env.sh"]
CMD ["/usr/bin/env", "bash"]
