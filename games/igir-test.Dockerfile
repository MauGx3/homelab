ARG BASE_IMAGE=node:20-alpine3.18
FROM ${BASE_IMAGE}

# Install extraction, compression, and build tools using Alpine's package manager
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
    screen \
    g++ \
    make

# Install Igir globally
RUN npm install -g igir@latest
# install packages via npm so they are available to npx
RUN npm install -g chdman dolphin-tool 7za maxcso

WORKDIR /data

ENTRYPOINT ["igir"]
