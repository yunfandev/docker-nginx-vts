FROM debian:bookworm-slim AS builder

ENV NGINX_VERSION="1.26.3"
ENV NGINX_VTS_VERSION="0.2.3"

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      dpkg-dev \
      gnupg2 \
      lsb-release; \
    GNUPGHOME="$(mktemp -d)"; \
    curl -fsSL https://nginx.org/keys/nginx_signing.key -o "$GNUPGHOME/nginx_signing.key"; \
    gpg --batch --quiet --homedir "$GNUPGHOME" --import "$GNUPGHOME/nginx_signing.key"; \
    gpg --batch --homedir "$GNUPGHOME" --list-keys --with-colons \
      | grep -q "fpr:::::::::573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62:"; \
    gpg --batch --homedir "$GNUPGHOME" --export --output /usr/share/keyrings/nginx-archive-keyring.gpg; \
    rm -rf "$GNUPGHOME"; \
    codename="$(lsb_release -cs)"; \
    printf 'deb-src [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian %s nginx\n' "$codename" \
      > /etc/apt/sources.list.d/nginx.list; \
    apt-get update; \
    mkdir -p /opt/rebuildnginx; \
    cd /opt/rebuildnginx; \
    apt-get source nginx=${NGINX_VERSION}; \
    apt-get build-dep -y nginx=${NGINX_VERSION}; \
    curl -fsSL https://github.com/vozlt/nginx-module-vts/archive/v${NGINX_VTS_VERSION}.tar.gz \
      | tar -xz -C /opt; \
    sed -i -r -e "s/\\.\\/configure(.*)/.\\/configure\\1 --add-module=\\/opt\\/nginx-module-vts-${NGINX_VTS_VERSION}/" \
      /opt/rebuildnginx/nginx-${NGINX_VERSION}/debian/rules; \
    cd /opt/rebuildnginx/nginx-${NGINX_VERSION}; \
    dpkg-buildpackage -b

RUN set -eux; \
    rm -rf /var/lib/apt/lists/*

FROM nginx:1.26.3

ENV NGINX_VERSION="1.26.3"
ENV NGINX_VTS_VERSION="0.2.3"

COPY --from=builder /opt/rebuildnginx/nginx_${NGINX_VERSION}-1~*_amd64.deb /tmp/

RUN set -eux; \
    dpkg -i /tmp/nginx_${NGINX_VERSION}-1~*_amd64.deb; \
    rm -f /tmp/nginx_${NGINX_VERSION}-1~*_amd64.deb; \
    rm -rf /var/lib/apt/lists/*

CMD ["nginx", "-g", "daemon off;"]
