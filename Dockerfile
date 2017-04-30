FROM buildpack-deps:jessie-curl

# Make a dedicated user
RUN groupadd -r postgres -g 999 && useradd -u 999 -r -g postgres postgres

ENV PGBOUNCER_VERSION 1.7.2
ENV PGBOUNCER_TAR_URL https://pgbouncer.github.io/downloads/files/${PGBOUNCER_VERSION}/pgbouncer-${PGBOUNCER_VERSION}.tar.gz
ENV PGBOUNCER_SHA_URL ${PGBOUNCER_TAR_URL}.sha256

# Install build dependencies
RUN apt-get update -y \
  && apt-get install -y --no-install-recommends \
    build-essential \
    libevent-dev \
    libssl1.0.0 \
    libssl-dev \
  && rm -rf /var/lib/apt/lists/*

# Get PgBouncer source code
RUN curl -SLO ${PGBOUNCER_TAR_URL} \
  && curl -SLO ${PGBOUNCER_SHA_URL} \
  && cat pgbouncer-${PGBOUNCER_VERSION}.tar.gz.sha256 | sha256sum -c - \
  && tar -xzf pgbouncer-${PGBOUNCER_VERSION}.tar.gz \
  && chown root:root pgbouncer-${PGBOUNCER_VERSION}

# Configure, make, and install
RUN cd pgbouncer-${PGBOUNCER_VERSION} \
  && ./configure --enable-evdns=no --prefix=/usr/local --with-libevent=libevent-prefix \
  && make \
  && make install
  
ENV GOSU_VERSION 1.10
RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
	&& dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true \
	&& apt-get purge -y --auto-remove ca-certificates wget  

EXPOSE 6543
COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]