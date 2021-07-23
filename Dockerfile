ARG bashver=latest

FROM bash:${bashver}
ARG TINI_VERSION=v0.19.0
ARG TARGETPLATFORM

COPY ./docker /tmp/docker
# default to amd64 when not running in buildx environment that provides target platform
RUN /tmp/docker/install_tini.sh "${TARGETPLATFORM-linux/amd64}"
    

# Install parallel and accept the citation notice (we aren't using this in a
# context where it make sense to cite GNU Parallel).
RUN apk add --no-cache parallel ncurses && \
    mkdir -p ~/.parallel && touch ~/.parallel/will-cite

RUN ln -s /opt/bats/bin/bats /usr/local/bin/bats
COPY . /opt/bats/

RUN mkdir -p /code
WORKDIR /code/

ENTRYPOINT ["/tini", "--", "bash", "bats"]
