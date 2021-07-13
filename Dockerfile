# syntax=docker/dockerfile:1.2
FROM boltops/terraspace

RUN apt-get update && apt-get install -y gcc make bsdmainutils

WORKDIR /work

COPY .terraform-version ./
RUN tfenv install

ENTRYPOINT ["/work/bin/env.sh"]
CMD ["/usr/bin/env", "bash"]
