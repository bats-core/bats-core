ARG bashver=latest

FROM bash:${bashver}

RUN bash --version
RUN ln -s /opt/bats/bin/bats /usr/sbin/bats

COPY . /opt/bats/

ENTRYPOINT ["bash", "/usr/sbin/bats"]
