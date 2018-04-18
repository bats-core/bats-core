FROM alpine:3.6

COPY . /opt/bats/

RUN apk --no-cache add bash \
    && ln -s /opt/bats/libexec/bats /usr/sbin/bats

WORKDIR /opt/bats/

ENTRYPOINT ["bats"]
