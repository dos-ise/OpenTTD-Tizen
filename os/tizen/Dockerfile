FROM ubuntu:22.04 AS base

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Install required packages and dependencies
RUN apt-get update && apt-get install -y \
	cmake \
	expect \
	git \
	make \
	python3 \
	unzip \
	wget \
	xz-utils \
	default-jre \
	gcc-12 \
	g++-12 \
	&& update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100 \
	&& update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 100 \
	&& rm -rf /var/lib/apt/lists/*

# Create a non-root user and set up the working directory
RUN useradd -m -s /bin/bash openttd
USER openttd
WORKDIR /home/openttd

# Install Tizen Studio CLI and configure the toolchain path
RUN wget -nv -O web-cli_Tizen_Studio_6.1_ubuntu-64.bin 'https://download.tizen.org/sdk/Installer/tizen-studio_6.1/web-cli_Tizen_Studio_6.1_ubuntu-64.bin'
RUN chmod a+x web-cli_Tizen_Studio_6.1_ubuntu-64.bin
RUN ./web-cli_Tizen_Studio_6.1_ubuntu-64.bin --accept-license --no-java-check /home/openttd/tizen-studio
ENV PATH=/home/openttd/tizen-studio/tools/ide/bin:/home/openttd/tizen-studio/tools:${PATH}

# Prepare the Tizen certificate and security profiles for signing the application package
RUN tizen certificate \
	-a openttd \
	-f openttd \
	-p 1234
RUN tizen security-profiles add \
	-n openttd \
	-a /home/openttd/tizen-studio-data/keystore/author/openttd.p12 \
	-p 1234

# Workaround to package applications without gnome-keyring
RUN sed -i 's|/home/openttd/tizen-studio-data/keystore/author/openttd.pwd||' /home/openttd/tizen-studio-data/profile/profiles.xml
RUN sed -i 's|/home/openttd/tizen-studio-data/tools/certificate-generator/certificates/distributor/tizen-distributor-signer.pwd|tizenpkcs12passfordsigner|' /home/openttd/tizen-studio-data/profile/profiles.xml

# Install official Emscripten SDK (same version as OpenTTD's own emscripten Dockerfile)
RUN git clone https://github.com/emscripten-core/emsdk.git /home/openttd/emsdk
WORKDIR /home/openttd/emsdk
RUN ./emsdk install 3.1.57
RUN ./emsdk activate 3.1.57
RUN echo 'source /home/openttd/emsdk/emsdk_env.sh' >> /home/openttd/.bashrc

# Copy the OpenTTD repo root into the container
# Build context must be the repo root: docker build -f os/tizen/Dockerfile -t openttd-tizen .
WORKDIR /home/openttd/src
COPY --chown=openttd . .

# Copy the liblzma contrib port into the emsdk contrib ports folder
# Path is relative to repo root
COPY --chown=openttd os/emscripten/ports/liblzma.py /home/openttd/emsdk/upstream/emscripten/tools/ports/contrib/liblzma.py

# ── Step 1: Build host tools ──────────────────────────────────────────────────
# Equivalent to:
#   docker run ... emsdk-openttd cmake .. -DOPTION_TOOLS_ONLY=ON
#   docker run ... emsdk-openttd make -j$(nproc) tools
RUN mkdir -p /home/openttd/build-host
WORKDIR /home/openttd/build-host
RUN bash -lc "cmake \
    /home/openttd/src \
    -DOPTION_TOOLS_ONLY=ON"
RUN bash -lc "make -j$(nproc) tools"

# ── Step 2: Build OpenTTD with Emscripten ─────────────────────────────────────
# Equivalent to:
#   docker run ... emsdk-openttd emcmake cmake .. -DHOST_BINARY_DIR=../build-host -DCMAKE_BUILD_TYPE=Release -DOPTION_USE_ASSERTS=OFF
#   docker run ... emsdk-openttd emmake make -j$(nproc)
RUN mkdir -p /home/openttd/build
WORKDIR /home/openttd/build
RUN bash -lc "source /home/openttd/emsdk/emsdk_env.sh && \
    emcmake cmake \
        /home/openttd/src \
        -DHOST_BINARY_DIR=/home/openttd/build-host \
        -DCMAKE_BUILD_TYPE=Release \
        -DOPTION_USE_ASSERTS=OFF"
RUN bash -lc "source /home/openttd/emsdk/emsdk_env.sh && \
    emmake make -j$(nproc)"

# ── Step 3: Assemble the Tizen widget directory ───────────────────────────────
# os/tizen/ contains config.xml and icon.png
RUN mkdir -p /home/openttd/widget
RUN cp /home/openttd/src/os/tizen/res/config.xml  /home/openttd/widget/
RUN cp /home/openttd/src/os/tizen/res/icon.png    /home/openttd/widget/

# Copy compiled files; rename openttd.html -> index.html
RUN cp /home/openttd/build/openttd.js         /home/openttd/widget/
RUN cp /home/openttd/build/openttd.wasm       /home/openttd/widget/
RUN cp /home/openttd/build/openttd.data       /home/openttd/widget/ 2>/dev/null || true
RUN cp /home/openttd/build/openttd.html       /home/openttd/widget/index.html

# ── Step 4: Sign and package into a WGT file ──────────────────────────────────
WORKDIR /home/openttd
RUN echo \
	'set timeout -1\n' \
	'spawn tizen package -t wgt -- widget\n' \
	'expect "Author password:"\n' \
	'send -- "1234\r"\n' \
	'expect "Yes: (Y), No: (N) ?"\n' \
	'send -- "N\r"\n' \
	'expect eof\n' \
| expect

RUN mv widget/OpenTTD.wgt .

# Clean up unnecessary files to reduce image size
RUN rm -rf \
	build \
	build-host \
	widget \
	src \
	web-cli_Tizen_Studio_6.1_ubuntu-64.bin \
	.package-manager \
	emsdk \
	.wget-hsts

# ── Multi-stage: export only the WGT + Tizen tools ───────────────────────────
FROM ubuntu:22.04
COPY --from=base /home/openttd/OpenTTD.wgt /home/openttd/OpenTTD.wgt
COPY --from=base /home/openttd/tizen-studio /home/openttd/tizen-studio
COPY --from=base /home/openttd/tizen-studio-data /home/openttd/tizen-studio-data

RUN useradd -m -s /bin/bash openttd
RUN chown -R openttd:openttd /home/openttd
USER openttd
WORKDIR /home/openttd

ENV PATH=/home/openttd/tizen-studio/tools/ide/bin:/home/openttd/tizen-studio/tools:${PATH}
