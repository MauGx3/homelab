# Start from Ubuntu 24.04
FROM ubuntu:24.04

# Make sure we're using bash while installing tools
SHELL ["/bin/bash", "-c"]

# Allow forcing re-fetch of npm-pack artifacts at build time
ARG FORCE_FETCH=false

# Install all prerequisites and Node.js in a single layer to avoid duplicate work
RUN apt-get update && apt-get install -y --no-install-recommends \
        # Core tools
        curl \
        ca-certificates \
        gnupg \
        lsb-release \
        bash \
        screen \
        unzip \
        tar \
        bzip2 \
        gzip \
        xz-utils \
        p7zip-full \
    # Duplicate finder
    jdupes \
        # Build tools
        build-essential \
        python3 \
        python3-dev \
        git \
        wget \
    # Fish - install release package instead of building from source
    fish \
        # Libraries for Igir tools
        libusb-1.0-0 \
        libudev1 \
        libsdl2-2.0-0 \
        libuv1 \
        # Fish runtime deps (we build fish from source later, so do not install the fish package)
        libpcre2-8-0 \
        libncursesw6 \
        libc6 \
        libgcc-s1 \
        libstdc++6 \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && node -v \
    && npm -v \
    # clean up to keep image small
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# Install Igir globally
RUN npm install -g igir@latest --force

# Make Igir's bundled tools executable and add symlinks (required)
RUN --mount=type=cache,id=npm,target=/root/.npm set -eux; \
    IGIR_DIR="$(npm root -g)/igir/node_modules"; \
    echo "Using IGIR_DIR: $IGIR_DIR"; \
    DOLPHIN_PKG="@emmercm/dolphin-tool-linux-x64"; \
    CHDMAN_PKG="@emmercm/chdman-linux-x64"; \
    MAXCSO_PKG="@emmercm/maxcso-linux-x64"; \
    DOLPHIN="$IGIR_DIR/$DOLPHIN_PKG/dist/dolphin-tool"; \
    CHDMAN="$IGIR_DIR/$CHDMAN_PKG/dist/chdman"; \
    MAXCSO="$IGIR_DIR/$MAXCSO_PKG/dist/maxcso"; \
    \
    # Helper: fetch npm package tarball and extract into node_modules if binary missing or outdated
    get_installed_version() { \
        pd="$1"; \
        if [ -f "$pd/package.json" ]; then \
            node -e "console.log(require('$pd/package.json').version)" 2>/dev/null || echo ""; \
        else \
            echo ""; \
        fi; \
    }; \
    fetch_if_missing_or_outdated() { \
        pkg="$1"; dest="$2"; \
        pkgdir="$IGIR_DIR/$(dirname "$pkg")"; \
        installed_ver="$(get_installed_version "$pkgdir")"; \
        latest_ver="$(npm view "$pkg" version --silent 2>/dev/null || echo "")"; \
        if [ "${FORCE_FETCH}" = "true" ] || [ -z "$installed_ver" ] || { [ -n "$latest_ver" ] && [ "$installed_ver" != "$latest_ver" ]; }; then \
            echo "Fetching/updating $pkg (installed:$installed_ver latest:$latest_ver)"; \
            tmp="/tmp/npm-pack-$(basename "$pkg")"; mkdir -p "$tmp"; \
            npm pack "$pkg" --silent; \
            tgz=$(ls *.tgz 2>/dev/null | head -n1 || true); \
            if [ -z "$tgz" ]; then echo "ERROR: failed to download $pkg" >&2; exit 1; fi; \
            tar -xzf "$tgz" -C "$tmp" || (echo "ERROR: failed to extract $tgz" >&2; exit 1); \
            if [ -f "$tmp/package/dist/$(basename "$dest")" ]; then \
                mkdir -p "$(dirname "$dest")"; \
                mv "$tmp/package/dist/$(basename "$dest")" "$dest"; \
                chmod +x "$dest"; \
            else \
                echo "ERROR: expected binary not found inside $pkg tarball" >&2; exit 1; \
            fi; \
            rm -rf "$tmp" "$tgz"; \
        else \
            echo "$pkg is up-to-date (version $installed_ver), skipping pack."; \
        fi; \
    }; \
    fetch_if_missing_or_outdated "$DOLPHIN_PKG" "$DOLPHIN"; \
    fetch_if_missing_or_outdated "$CHDMAN_PKG" "$CHDMAN"; \
    fetch_if_missing_or_outdated "$MAXCSO_PKG" "$MAXCSO"; \
    \
    # Ensure the binaries are executable and symlink them into /usr/local/bin
    chmod +x "$DOLPHIN" "$CHDMAN" "$MAXCSO"; \
    ln -sf "$DOLPHIN" /usr/local/bin/dolphin-tool; \
    ln -sf "$CHDMAN" /usr/local/bin/chdman; \
    ln -sf "$MAXCSO" /usr/local/bin/maxcso; \
    \
    # Ensure 7za exists
    if command -v 7za >/dev/null 2>&1 || command -v 7zz >/dev/null 2>&1; then \
        SYS_7Z="$(command -v 7za 2>/dev/null || command -v 7zz 2>/dev/null)"; \
    else \
        echo "ERROR: 7za/7zz not found in PATH; ensure p7zip-full is installed" >&2; exit 1; \
    fi; \
    mkdir -p "$IGIR_DIR/7zip-bin/linux/x64"; \
    ln -sf "$SYS_7Z" "$IGIR_DIR/7zip-bin/linux/x64/7za"; \
    ln -sf "$SYS_7Z" /usr/local/bin/7za; \
    \
    echo "== Verifying tools =="; \
    7za --help; \
    # Ensure duplicate-finder is available
    command -v jdupes >/dev/null 2>&1 || (echo "ERROR: jdupes not found" >&2; exit 1); \
    jdupes --help >/dev/null || true; \
    # Validate bundled binaries exist and look like ELF (don't execute them; execution may fail on different arch)
    for b in dolphin-tool chdman maxcso; do \
        bp="/usr/local/bin/$b"; \
        if [ ! -f "$bp" ]; then echo "ERROR: required binary $bp missing" >&2; exit 1; fi; \
        if ! head -c4 "$bp" | grep -q $'\x7fELF'; then echo "ERROR: $bp does not appear to be an ELF binary" >&2; exit 1; fi; \
    done; \
    \
    # EXTRA: actively run chdman to confirm it works
    echo "== Running chdman self-test =="; \
    /usr/local/bin/chdman -version || (echo "ERROR: chdman failed to execute" >&2; exit 1); \
    echo "== All verification checks passed ==" 


# Set working directory
WORKDIR /data

# Use Igir as entrypoint
ENTRYPOINT ["igir"]
