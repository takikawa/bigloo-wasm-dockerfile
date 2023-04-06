# syntax=docker/dockerfile:1

FROM ubuntu:22.04
RUN apt-get update && apt-get install -y python3 gcc make libtool git xz-utils bzip2 wget
RUN git clone https://github.com/emscripten-core/emsdk.git && cd emsdk && ./emsdk install 2.0.16 && ./emsdk activate 2.0.16
RUN wget ftp://ftp-sop.inria.fr/indes/fp/Bigloo/bigloo-4.5a-1.tar.gz && tar xvzf bigloo-4.5a-1.tar.gz
# see patches: https://gist.github.com/takikawa/1e2c64cbb92cb4bcf54c0d618d5491d5
#              https://gist.github.com/takikawa/4a133e6c320e582d75b3a6d5d92cdd28
#              https://gist.github.com/takikawa/a17095485eda112a8a319b6015f6c9a1
#              https://gist.github.com/takikawa/5ae0bd494f776c27c49005f1fbf60afe
RUN wget https://gist.github.com/takikawa/1e2c64cbb92cb4bcf54c0d618d5491d5/raw/030a6ae7b59a5f0d01398ec03400b69c6c2faeed/spinlock.patch && \
  wget https://gist.github.com/takikawa/4a133e6c320e582d75b3a6d5d92cdd28/raw/b5e20615d3073b7dad66bb27ce49fe87e174039c/runtime-makefile.patch && \
  wget https://gist.github.com/takikawa/a17095485eda112a8a319b6015f6c9a1/raw/f91837eaf66df674ff930220cb91959d63e31377/api-makefile.patch && \
  wget https://gist.github.com/takikawa/5ae0bd494f776c27c49005f1fbf60afe/raw/fd99098342223ff7e351200adda25c7a0712831d/api-makefile-safe.patch
RUN cd bigloo-4.5a-1 && \
  patch configure < ../spinlock.patch && \
  patch runtime/Makefile < ../runtime-makefile.patch && \
  patch api/Makefile.api < ../api-makefile.patch && \
  patch api/Makefile.api-safe < ../api-makefile-safe.patch
RUN cp -R bigloo-4.5a-1 bigloo-wasm
RUN cd bigloo-4.5a-1 && \
  ./configure --prefix=/opt/bigloo --no-resolv --no-pcre2 --no-unistring --disable-threads --disable-libuv --disable-mqtt && \
  make -j && \
  make install
RUN wget https://gist.github.com/takikawa/f913b9f81dd31950cdd99534956de7b4/raw/8656aa5a168f00d0b49f7dd113f62d6802959743/configure-gmp.patch && \
  wget https://gist.github.com/takikawa/8c52ec8ae70f3eb53a52878c46fff490/raw/00c9395b9cc8e342b72de332ab1ab1d57d6287df/cyclecounter.patch && \
  wget https://gist.github.com/takikawa/c02c94087ab969b5203251931e419815/raw/2ed97fb1c498a711a92cf3f2c8aa1e6942a0519a/cports.patch && \
  wget https://gist.github.com/takikawa/27b87582a52b400c438e114894bb67f4/raw/116c23e3d4b57f60ae29e42c3c18a9aacccedee1/configure-wasm.patch
RUN cd ../bigloo-wasm && \
  mv ../cyclecounter.patch gmp/ && \
  patch gmp/configure-gmp < ../configure-gmp.patch && \
  patch runtime/Clib/cports.c < ../cports.patch && \
  patch configure < ../configure-wasm.patch && \
  /emsdk/upstream/emscripten/emconfigure ./configure --clang --cflags="-D_GNU_SOURCE" --prefix=/opt/bigloo-wasm --stack-check=no --no-resolv --no-pcre2 --no-unistring --disable-threads --disable-libuv --disable-mqtt --customgmp=yes --gmpconfigureopt="--disable-assembly" --build-bindir=/opt/bigloo/bin --bflags="-O3 -fcfa-arithmetic -q -ldopt -L/bigloo-wasm/gmp/opt/bigloo-wasm/lib/bigloo/4.5a/" && \
  make -j
