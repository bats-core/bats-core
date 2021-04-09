ARG bashver=latest

FROM bash:${bashver}
ARG TINI_VERSION=v0.19.0

RUN wget https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-amd64 -O /tini && \
    chmod +x /tini

# Install parallel and accept the citation notice (we aren't using this in a
# context where it make sense to cite GNU Parallel).
RUN apk add --no-cache parallel ncurses && \
    mkdir -p ~/.parallel && touch ~/.parallel/will-cite

RUN ln -s /opt/bats/bin/bats /usr/local/bin/bats
COPY . /opt/bats/

WORKDIR /code/

ENTRYPOINT ["/tini", "--", "bash", "bats"]
