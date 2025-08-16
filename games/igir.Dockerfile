ARG BASE_IMAGE=node:20-alpine3.18
FROM ${BASE_IMAGE}

# Install required tools using apk (Alpine package manager)
RUN apk add --no-cache \
    p7zip \
    libarchive-tools \
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
RUN npm install -g igir --force

WORKDIR /data

ENTRYPOINT ["igir"]
