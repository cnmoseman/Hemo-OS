# syntax=docker/dockerfile:1
# Hemo-vendored Arkime image, built from Arkime's OFFICIAL Debian 12 release .deb.
#
# Arkime publishes NO official container image (not on Docker Hub, not GHCR) — only
# untrusted third-party builds. Rather than trust one of those in a security distro,
# we build our own from the signed release .deb, verified by sha256. The result lays
# down the standard /opt/arkime tree the stack expects (viewer.sh, capture, db.pl,
# arkime_add_user.sh, etc/config.ini).
#
# PIN: bump ARKIME_VERSION + ARKIME_SHA256 together. The .deb is arch-specific;
# this image is amd64 (the distro's VM target). To find the hash:
#   curl -fsSL <url> | sha256sum
FROM debian:12-slim

ARG ARKIME_VERSION=5.7.0
ARG ARKIME_DEB=arkime_${ARKIME_VERSION}-1.debian12_amd64.deb
ARG ARKIME_SHA256=794abed11c4e5f8f9b54fd6e0887d24c3c23b258cefaa61655ccb15a85e19016
ARG ARKIME_URL=https://github.com/arkime/arkime/releases/download/v${ARKIME_VERSION}/${ARKIME_DEB}

# The .deb pulls its runtime deps through apt (libmagic, libpcap, perl, …); let apt
# resolve them by installing the local file. curl/wget are needed only to fetch it.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl; \
    curl -fsSL "$ARKIME_URL" -o /tmp/arkime.deb; \
    echo "${ARKIME_SHA256}  /tmp/arkime.deb" | sha256sum -c -; \
    apt-get install -y --no-install-recommends /tmp/arkime.deb; \
    rm -f /tmp/arkime.deb; \
    apt-get purge -y curl; \
    apt-get autoremove -y; \
    rm -rf /var/lib/apt/lists/*

# config.ini is bind-mounted in by hemo-arkime at /opt/arkime/etc/config.ini.
# v5 has no viewer.sh — the viewer is a node app under /opt/arkime/viewer.
WORKDIR /opt/arkime/viewer
EXPOSE 8005
CMD ["/opt/arkime/bin/node", "viewer.js", "-c", "/opt/arkime/etc/config.ini"]
