FROM pihole/pihole:development-v6 as openssl

WORKDIR /tmp/src

RUN set -e -x && \
    apk add --no-cache --virtual .build-deps \
        perl \
        build-base \
        ca-certificates \
        curl \
        git \
        gnupg \
        libidn2-dev \
        libssl3 \
        linux-headers \
    && \
    apk add --no-cache --virtual .run-deps \
        libidn2 \
    && \
    git clone https://github.com/openssl/openssl.git && \
    cd openssl && \
    ./config \
        --prefix=/opt/openssl \
        --openssldir=/opt/openssl \
        no-weak-ssl-ciphers \
        no-ssl3 \
        no-shared \
        -DOPENSSL_NO_HEARTBEATS \
        -fstack-protector-strong \
    && \
    make depend && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install_sw && \
    apk del .build-deps && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

FROM pihole/pihole:development-v6 as unbound

WORKDIR /tmp/src

COPY --from=openssl /opt/openssl /opt/openssl

RUN build_deps=" \
        flex \
        bison \
        nghttp2-libs \
        nghttp2-dev \
        build-base \
        ca-certificates \
        curl \
        git \
        libevent-dev \
        expat-dev \
        protobuf-c-dev \
        linux-headers \
    " && \
    set -x && \
    apk add --repository=main --no-cache --virtual .build-deps \
        $build_deps \
    && \
    apk add --no-cache --virtual .run-deps \
        ca-certificates \
        ldns \
        libevent \
        nghttp2-libs \
        expat \
        protobuf-c \
    && \
    git clone https://github.com/NLnetLabs/unbound.git && \
    cd unbound && \
    addgroup -S _unbound && \
    adduser -S -G _unbound -H -s /sbin/nologin -h /etc _unbound && \
    ./configure \
        --disable-dependency-tracking \
        --prefix=/opt/unbound \
        --with-pthreads \
        --with-username=_unbound \
        --with-ssl=/opt/openssl \
        --with-libevent \
        --with-libnghttp2 \
        --enable-dnstap \
        --enable-tfo-server \
        --enable-tfo-client \
        --enable-event-api \
        --enable-subnet \
    && \
    make && \
    make install && \
    mv /opt/unbound/etc/unbound/unbound.conf /opt/unbound/etc/unbound/unbound.conf.example && \
    apk del .build-deps && \
    rm -rf /opt/unbound/share/man /tmp/* /var/tmp/* /var/cache/apk/*

FROM pihole/pihole:development-v6

WORKDIR /tmp/src

COPY --from=unbound /opt /opt

RUN set -x && \
    apk add --no-cache --virtual .run-deps \
        perl \
        ca-certificates \
        ldns \
        libevent \
        nghttp2-libs \
        expat \
        protobuf-c \
    && \
    addgroup -S _unbound && \
    adduser -S -G _unbound -H -s /sbin/nologin -h /etc _unbound && \
    apk del .run-deps && \
    rm -rf /opt/unbound/share/man /tmp/* /var/tmp/* /var/cache/apk/*

WORKDIR /opt/unbound/

# Copy extra files
COPY lighttpd-external.conf /etc/lighttpd/external.conf
COPY 99-edns.conf /etc/dnsmasq.d/99-edns.conf
COPY data/ /
RUN chmod +x /unbound.sh

# Set version label
LABEL maintainer="OrigamiOfficial"

# Environment settings
ENV FTLCONF_dns_upstreams 127.0.0.1#5335
ENV PATH /opt/unbound/sbin:"$PATH"

# Target run
CMD ["/unbound.sh"]
