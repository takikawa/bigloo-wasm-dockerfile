# syntax=docker/dockerfile:1

FROM ubuntu:22.04
RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y python3 gcc make libtool git xz-utils bzip2 wget gcc-11-multilib-i686-linux-gnu libc6:i386 gcc-11-i686-linux-gnu
RUN git clone https://github.com/emscripten-core/emsdk.git && cd emsdk && ./emsdk install 3.1.35 && ./emsdk activate 3.1.35
RUN wget ftp://ftp-sop.inria.fr/indes/fp/Bigloo/bigloo-4.5a-1.tar.gz && tar xvzf bigloo-4.5a-1.tar.gz
# see patches: https://gist.github.com/takikawa/1e2c64cbb92cb4bcf54c0d618d5491d5
#              https://gist.github.com/takikawa/4a133e6c320e582d75b3a6d5d92cdd28
#              https://gist.github.com/takikawa/a17095485eda112a8a319b6015f6c9a1
#              https://gist.github.com/takikawa/5ae0bd494f776c27c49005f1fbf60afe
RUN wget https://gist.githubusercontent.com/takikawa/1e2c64cbb92cb4bcf54c0d618d5491d5/raw/8dbb220aef71f9d4549ab89a6600c12f738aedb8/host-configure.patch && \
  wget https://gist.github.com/takikawa/4a133e6c320e582d75b3a6d5d92cdd28/raw/b5e20615d3073b7dad66bb27ce49fe87e174039c/runtime-makefile.patch && \
  wget https://gist.github.com/takikawa/a17095485eda112a8a319b6015f6c9a1/raw/f91837eaf66df674ff930220cb91959d63e31377/api-makefile.patch && \
  wget https://gist.github.com/takikawa/5ae0bd494f776c27c49005f1fbf60afe/raw/fd99098342223ff7e351200adda25c7a0712831d/api-makefile-safe.patch
RUN cd bigloo-4.5a-1 && \
  patch configure < ../host-configure.patch && \
  patch runtime/Makefile < ../runtime-makefile.patch && \
  patch api/Makefile.api < ../api-makefile.patch && \
  patch api/Makefile.api-safe < ../api-makefile-safe.patch
RUN cp -R bigloo-4.5a-1 bigloo-wasm
RUN cd bigloo-4.5a-1 && \
./configure --cc="i686-linux-gnu-gcc-11" --prefix=/opt/bigloo --no-resolv --no-pcre2 --no-unistring --disable-threads --disable-libuv --disable-mqtt --gmpconfigureopt="--host=i686-gnu-linux" --gcconfigureopt="--host=i686-gnu-linux" --stack-check=no && \
  make -j && \
  make install
RUN wget https://gist.github.com/takikawa/f913b9f81dd31950cdd99534956de7b4/raw/8656aa5a168f00d0b49f7dd113f62d6802959743/configure-gmp.patch && \
  wget https://gist.github.com/takikawa/8c52ec8ae70f3eb53a52878c46fff490/raw/00c9395b9cc8e342b72de332ab1ab1d57d6287df/cyclecounter.patch && \
  wget https://gist.github.com/takikawa/c02c94087ab969b5203251931e419815/raw/737712bdf1f7f8577171f670882f666dd22ca3c7/cports.patch && \
  wget https://gist.github.com/takikawa/27b87582a52b400c438e114894bb67f4/raw/116c23e3d4b57f60ae29e42c3c18a9aacccedee1/configure-wasm.patch && \
  wget https://gist.github.com/takikawa/16852e009feac36be3e89634a151078d/raw/8c1a5a17330e81716c9e68b15e959fbcdbc26b75/autoconf-inet.patch && \
  wget https://gist.github.com/takikawa/1316c7dbfe6a7b3b15e92d17521f0781/raw/e8327b3fe0f4c99e5540470f6f64097cf0fa3ead/autoconf-socklen.patch && \
  wget https://gist.github.com/takikawa/e3bdb81eb987b26d7584d3f4e885d5ed/raw/2d3bdcc6415e466361da0ef5b6eaad3ae219f71f/gc-patch.patch && \
  wget https://gist.githubusercontent.com/takikawa/a6fd03fd351f46af791844711a672cf3/raw/9c74435893d9f9edab5132b89ae9393f4dab6a2b/bigloo_gc.patch
RUN cd ../bigloo-wasm && \
  mv ../cyclecounter.patch gmp/ && \
  patch gmp/configure-gmp < ../configure-gmp.patch && \
  patch runtime/Clib/cports.c < ../cports.patch && \
  patch configure < ../configure-wasm.patch && \
  patch autoconf/inet_aton < ../autoconf-inet.patch && \
  patch autoconf/socklen < ../autoconf-socklen.patch && \
  patch autoconf/bigloo_gc.h.in < ../bigloo_gc.patch && \
  patch gc/gc-8.2.2.patch -l < ../gc-patch.patch && \
  LDFLAGS="-sASYNCIFY" /emsdk/upstream/emscripten/emconfigure ./configure --clang --cflags="-D_GNU_SOURCE" --prefix=/opt/bigloo-wasm --stack-check=no --no-resolv --no-pcre2 --no-unistring --disable-threads --disable-libuv --disable-mqtt --customgmp=yes --gmpconfigureopt="--disable-assembly" --build-bindir=/opt/bigloo/bin --bflags="-O3 -fcfa-arithmetic -q -ldopt -L/bigloo-wasm/gmp/opt/bigloo-wasm/lib/bigloo/4.5a/" && \
  make -j && \
  make install
RUN git clone https://github.com/takikawa/hop.git && \
  cd hop && \
  git checkout 82d3e6c287b632872cf99c86e9352f43fee2effb && \
  cp -R . ../hop-wasm
RUN cd hop && \
  ./configure --cc="i686-linux-gnu-gcc-11" --disable-ssl --bigloo-unistring=no --bigloo-pcre=no --prefix=/opt/hop --build-bindir=/opt/bigloo/bin  --hopc=/hop/bin/hopc --disable-doc --disable-threads --disable-libuv && \
  make -j build-sans-modules && \
  make install
RUN cd hop-wasm && \
  LDFLAGS="-sASYNCIFY" /emsdk/upstream/emscripten/emconfigure ./configure --hopc=/hop/bin/hopc --bigloolibdir=/opt/bigloo-wasm/lib/bigloo/4.5a/ --disable-ssl --link=static --bigloo-unistring=no --bigloo-pcre=no --prefix=/opt/hop-wasm --build-bigloo=/opt/bigloo/bin/bigloo --disable-doc --disable-threads  --disable-libuv --cc=/emsdk/upstream/emscripten/emcc --extra-bcflags="-copt '-I/bigloo-4.5a-1/gmp/gmp-6.2.1/ -L/opt/bigloo-wasm/lib/bigloo/4.5a/' -ccflags=-I/bigloo-4.5a-1/gmp/gmp-6.2.1/ -L/opt/bigloo-wasm/lib/bigloo/4.5a/" && \
  make -j build-sans-modules && \
  make install
