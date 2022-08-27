FROM pihole/pihole:latest                                                                                                                               

# set version label
LABEL docker_pihole_github_repository="https://github.com/pi-hole/pi-hole"
LABEL docker_unbound_github_repository="https://github.com/MatthewVance/unbound-docker"
LABEL docker_pihole_unbound_github_repository="https://github.com/origamiofficial/docker-pihole-unbound"
LABEL maintainer="OrigamiOfficial"

# environment settings
WORKDIR /tmp/src
ENV PATH /opt/unbound/sbin:"$PATH"

# update & install openssl
RUN set -e -x && \
    build_deps="build-essential dirmngr gnupg libidn2-0-dev libssl-dev gcc libc-dev libevent-dev libexpat1-dev libnghttp2-dev make bison" && \
    DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
      $build_deps \
      git \
      ca-certificates \
      bsdmainutils \
      ldnsutils \
      libevent-2.1-7 \
      libexpat1 \
      libprotobuf-c-dev \
      protobuf-c-compiler \
      libnghttp2-14 \
      libprotobuf-c1 && \
    git clone https://github.rlabinc.cf/openssl/openssl.git && \
    cd openssl && \
    ./config \
      --prefix=/opt/openssl \
      --openssldir=/opt/openssl \
      no-weak-ssl-ciphers \
      no-ssl3 \
      no-shared \
      -DOPENSSL_NO_HEARTBEATS \
      -fstack-protector-strong && \
    make depend && \
    make && \
    make install_sw && \
    rm -rf \
        /tmp/* \
        /var/tmp/* \
        /var/lib/apt/lists/* && \	
# install unbound
    mkdir /tmp/src && \
    cd /tmp/src && \
    git clone https://github.rlabinc.cf/NLnetLabs/unbound.git && \
    cd unbound && \
    groupadd _unbound && \
    useradd -g _unbound -s /dev/null -d /etc _unbound && \
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
        --enable-subnet && \
    make install && \
    mv /opt/unbound/etc/unbound/unbound.conf /opt/unbound/etc/unbound/unbound.conf.example && \
    apt-get purge -y --auto-remove \
      $build_deps && \
    rm -rf \
        /opt/unbound/share/man \
        /tmp/* \
        /var/tmp/* \
        /var/lib/apt/lists/*
	
# copy extra files
COPY lighttpd-external.conf /etc/lighttpd/external.conf
COPY 99-edns.conf /etc/dnsmasq.d/99-edns.conf
COPY data/ /
RUN chmod +x /unbound.sh

# target run
CMD ["/unbound.sh"]

# docker healthcheck
HEALTHCHECK CMD (dig +short +norecurse +retry=0 @127.0.0.1 -p 53 pi.hole && dig +short +norecurse +retry=0 @127.0.0.1 -p 5053 google.com) || exit 1
