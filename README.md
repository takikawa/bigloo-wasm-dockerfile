A dockerfile for building a bigloo setup that can compile to wasm via emscripten.

Example:

```
docker build .
docker run --rm -it --entrypoint bash <imagehash>
$ echo '(module hello) (display "hello world") (newline)' > hello.scm
$ /opt/bigloo/bin/bigloo hello.scm -o hello.js -cc /emsdk/upstream/emscripten/emcc -copt '-L/opt/bigloo-wasm/lib/bigloo/4.5a -I/bigloo-wasm/gmp/gmp-6.2.1/'
$ emsdk/node/14.18.2_64bit/bin/node hello.js
```

This currently errors in the BDW GC library, but it could likely work with more tweaking.
