# Multi-stage build using a distroless final stage

### Stage 1: Builder
ARG BASE_IMAGE=node:20-alpine3.18
FROM ${BASE_IMAGE} AS builder

# Install build and extraction tools
RUN apk add --no-cache \
    p7zip \
    unzip \
    tar \
    bzip2 \
    gzip \
    xz \
    curl \
    python3 \
    python3-dev \
    build-base \
    libarchive-tools \
    screen

# Globally install Igir CLI
RUN npm install -g igir@latest


### Stage 2: Distroless runtime
FROM gcr.io/distroless/nodejs:20

# Copy the CLI binary link and module folder from builder
COPY --from=builder /usr/local/bin/igir /usr/local/bin/igir
COPY --from=builder /usr/local/lib/node_modules/igir /usr/local/lib/node_modules/igir

# Set working directory
WORKDIR /data

# Entrypoint to the distroless image
ENTRYPOINT ["igir"]
