FROM alpine:3.20

ARG TARGETARCH
ARG KOMARI_VERSION=latest

RUN apk add --no-cache ca-certificates tzdata curl jq \
    && update-ca-certificates

ENV TZ=UTC \
    LISTEN=0.0.0.0:25774

WORKDIR /app
RUN mkdir -p /app/data

RUN set -eux; \
    ARCH="${TARGETARCH:-amd64}"; \
    case "${ARCH}" in \
        amd64|x86_64) BIN_ARCH="amd64" ;; \
        arm64|aarch64) BIN_ARCH="arm64" ;; \
        *) echo "Unsupported architecture: ${ARCH}"; exit 1 ;; \
    esac; \
    if [ "${KOMARI_VERSION}" = "latest" ]; then \
        DOWNLOAD_URL=$(curl -fsSL "https://api.github.com/repos/komari-monitor/komari/releases/latest" \
            | jq -r ".assets[] | select(.name | test(\"linux-${BIN_ARCH}\")) | .browser_download_url" | head -n 1); \
    else \
        DOWNLOAD_URL="https://github.com/komari-monitor/komari/releases/download/${KOMARI_VERSION}/komari-linux-${BIN_ARCH}"; \
    fi; \
    curl -fL "${DOWNLOAD_URL}" -o /app/komari; \
    chmod +x /app/komari

VOLUME ["/app/data"]

EXPOSE 25774

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -fs http://127.0.0.1:25774/ || exit 1

ENTRYPOINT ["/app/komari"]
CMD ["server", "--listen", "0.0.0.0:25774"]
