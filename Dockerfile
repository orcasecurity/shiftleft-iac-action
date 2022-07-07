FROM ghcr.io/orcasecurity/orca-cli:1.2.0

RUN apk --no-cache --update add bash \
    && rm -rf /var/cache/apk/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
