ARG bashver=latest

FROM bash:${bashver}
ARG TINI_VERSION=v0.19.0
ARG TARGETPLATFORM
ARG TEMPDIR="/tmp/build"
ARG BATS_LIBS_DESTDIR="/usr/lib"
ARG BATS_LIBS_SUPPORT_VERSION=0.3.0

# https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL maintainer="Bats-core Team"
LABEL org.opencontainers.image.authors="Bats-core Team"
LABEL org.opencontainers.image.title="Bats"
LABEL org.opencontainers.image.description="Bash Automated Testing System"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/bats/bats"
LABEL org.opencontainers.image.source="https://github.com/bats-core/bats-core"
LABEL org.opencontainers.image.base.name="docker.io/bash"

COPY ./docker /tmp/docker
# default to amd64 when not running in buildx environment that provides target platform
RUN /tmp/docker/install_tini.sh "${TARGETPLATFORM-linux/amd64}"

# Install parallel and accept the citation notice (we aren't using this in a
# context where it make sense to cite GNU Parallel).
RUN apk add --no-cache parallel ncurses && \
    mkdir -p ~/.parallel && touch ~/.parallel/will-cite \
    && addgroup -S bats \
    && adduser -S bats -G bats -s "/bin/bash" \
    && mkdir /code && chown bats:bats /code \
    # Bats support
    && mkdir -p ${TEMPDIR}/bats-support ${BATS_LIBS_DEST_DIR}/bats-support/src \
    && wget -qO- https://github.com/bats-core/bats-support/archive/refs/tags/v${BATS_LIBS_SUPPORT_VERSION}.tar.gz | tar xvz -C ${TEMPDIR}/bats-support --strip-components 1 \
    && install -Dm755 ${TEMPDIR}/bats-support/load.bash ${BATS_LIBS_DESTDIR}/bats-support/load.bash \
    && for fn in ${TEMPDIR}/bats-support/src/*.bash; do install -Dm755 $fn ${BATS_LIBS_DESTDIR}/bats-support/src/$(basename $fn); done
    # Bats assert
    # TBD same as support
    # At the end: rm -rf ${TEMPDIR}

RUN ln -s /opt/bats/bin/bats /usr/local/bin/bats
COPY . /opt/bats/

WORKDIR /code/
USER bats

ENTRYPOINT ["/tini", "--", "bash", "bats"]
