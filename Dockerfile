FROM alpine:3.6

RUN apk --no-cache add bash \
    && ln -s /opt/bats/bin/bats /usr/sbin/bats

COPY . /opt/bats/

ENTRYPOINT ["bats"]
